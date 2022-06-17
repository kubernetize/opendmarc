FROM alpine:3.16

LABEL maintainer="Richard Kojedzinszky <richard@kojedz.in>"

RUN \
    addgroup -g 8893 opendmarc && \
    adduser -h /run/opendmarc -S -D -H -G opendmarc -u 8893 opendmarc && \
    apk --no-cache add opendmarc && \
    sed -i \
        -e '/^BaseDirectory/s/^/#/' \
        -e '/^IgnoreHosts/s/^/#/' \
	-e '/^Socket/s/@localhost//' \
	/etc/opendmarc/opendmarc.conf

USER 8893

CMD ["/usr/sbin/opendmarc", "-c", "/etc/opendmarc/opendmarc.conf", "-f"]
