FROM arm64v8/alpine:edge
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64"

# Environment
ARG PDNS_REC_VERSION=4.1.2
ENV TZ=Asia/Tokyo

# package install 
# https://wiki.alpinelinux.org/wiki/Alpine_Linux_package_management#Repository_pinning
RUN echo "@edgecommunity http://dl-cdn.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories \
    && echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
    && apk add --update --upgrade \
      tzdata \
      libressl2.7-libcrypto@edge \
      boost-system@edge \
      boost-filesystem@edge \
      boost-regex@edge \
      boost-thread@edge \
      boost@edge \
      protobuf@edge \
      pdns-recursor@edgecommunity \
    && apk del --purge \
    && rm -rf /var/lib/apt/lists/* 

# execute
WORKDIR /etc/pdns
VOLUME ["/etc/pdns"]

# export TCP and UDP
EXPOSE 53/TCP 53/UDP
CMD ["/usr/sbin/pdns_recursor", "--daemon=no", "--write-pid=no", "--disable-syslog", "--log-timestamp=yes"]
