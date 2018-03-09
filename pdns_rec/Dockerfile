# Environment
FROM arm64v8/debian:testing-slim
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64"
ENV PDNS_REC_VERSION 4.1.1
ENV DEBIAN_FRONTEND noninteractive
ENV TZ Asia/Tokyo

# package install 
RUN apt-get update \
      && apt-get -qq install pdns-recursor/testing \
      && apt-get clean \
      && apt-get purge --auto-remove -y \
      && rm -rf /var/lib/apt/lists/* \
      && ln -snf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# execute
WORKDIR /etc/powerdns
VOLUME ["/etc/powerdns"]

# export TCP and UDP
EXPOSE 53/TCP 53/UDP
CMD ["/usr/sbin/pdns_recursor", "--daemon=no", "--write-pid=no", "--disable-syslog", "--log-timestamp=yes"]
