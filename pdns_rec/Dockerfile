FROM arm64v8/alpine:edge
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64"

# Environment
ARG PDNS_REC_VERSION=4.1.2
ENV TZ=Asia/Tokyo

# package install 
RUN apk add --update --no-cache pdns-recursor \
      && apk del --purge \
      && rm -rf /var/lib/apt/lists/* \
      && ln -snf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# execute
WORKDIR /etc/powerdns
VOLUME ["/etc/powerdns"]

# export TCP and UDP
EXPOSE 53/TCP 53/UDP
CMD ["/usr/sbin/pdns_recursor", "--daemon=no", "--write-pid=no", "--disable-syslog", "--log-timestamp=yes"]
