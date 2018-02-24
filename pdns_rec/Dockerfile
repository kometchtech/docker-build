FROM arm64v8/debian:9.3
MAINTAINER kometchtech <kometch@gmail.com>
ENV PDNS_REC_VERSION 4.1.1
CMD 'echo "deb http://httpredir.debian.org/debian testing main" >> /etc/apt/sources.list.d/testing.list' 
RUN apt-get update \
    && apt-get -qq install \
      pdns-recursor/testing 
WORKDIR /pdns-recursor-${PDNS_REC_VERSION}
RUN rm -rf /var/lib/apt/lists/*
WORKDIR /etc/powerdns
VOLUME ["/etc/powerdns"]
EXPOSE 53 53/udp
ENTRYPOINT ["/usr/sbin/pdns_recursor", "--daemon=no", "--write-pid=no", "--disable-syslog", "--log-timestamp=yes"]
