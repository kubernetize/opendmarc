FROM debian:bookworm-slim AS build

ARG pkgver=rel-opendmarc-1-4-2

RUN \
    apt update && apt install -y curl gcc make patch libmilter-dev libspf2-dev autoconf automake libtool && \
    mkdir /opendmarc && \
    curl -sL https://github.com/trusteddomainproject/OpenDMARC/archive/refs/tags/$pkgver.tar.gz | \
    tar xzf - -C /opendmarc --strip-components=1

COPY patches patches

WORKDIR /opendmarc

RUN for p in /patches/*.patch; do echo "* Applying $p"; patch -p1 < "$p"; done

RUN autoreconf -vif

RUN ./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --mandir=/usr/share/man \
    --localstatedir=/var \
    --with-installdir=/usr \
    --with-spf \
    --with-spf2-lib=/usr/lib \
    --with-spf2-include=/usr/include/spf2 \
    --disable-dependency-tracking

RUN make

RUN make install

RUN strip -s /usr/sbin/opendmarc /usr/lib/libopendmarc.so.2

FROM debian:bookworm-slim

LABEL maintainer="Richard Kojedzinszky <richard@kojedz.in>"

COPY --from=build /usr/sbin/opendmarc /usr/sbin/
COPY --from=build /usr/lib/libopendmarc.so.2 /usr/lib/
COPY --from=build /usr/share/doc/opendmarc /usr/share/doc/opendmarc
COPY --from=build /usr/share/doc/opendmarc/opendmarc.conf.sample /etc/opendmarc.conf

RUN \
    useradd -u 8893 -d /run/opendmarc -M opendmarc && \
    apt update && \
    apt install -y libmilter1.0.1 libspf2-2 && \
    apt clean && \
    rm -rf /var/cache/apt/* /var/lib/apt/lists/* && \
    sed -i \
    -e '/^BaseDirectory/s/^/#/' \
    -e '/^IgnoreHosts/s/^/#/' \
    -e '/^Socket/s/@localhost//' \
    /etc/opendmarc.conf

USER 8893

CMD ["/usr/sbin/opendmarc", "-c", "/etc/opendmarc.conf", "-f"]
