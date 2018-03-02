# Environment
FROM arm64v8/debian:9.3-slim
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64"
ENV PDNS_REC_VERSION 4.1.1
ENV TZ Asia/Tokyo

# package install 
RUN 'echo "deb http://httpredir.debian.org/debian testing main" >> /etc/apt/sources.list.d/testing.list' 
RUN apt-get update \
      && apt-get -qq install pdns-recursor/testing \
      && apt-get clean \
      && apt-get purge --auto-remove -y \
      rm -rf /var/lib/apt/lists/* \
      && ln -snf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# execute
WORKDIR /etc/powerdns
VOLUME ["/etc/powerdns"]

# export TCP and UDP
EXPOSE 53/TCP 53/TCP
CMD ["/usr/sbin/pdns_recursor", "--daemon=no", "--write-pid=no", "--disable-syslog", "--log-timestamp=yes"]
