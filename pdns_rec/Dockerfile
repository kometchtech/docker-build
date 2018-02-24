FROM arm64v8/debian:9.3-slim
MAINTAINER kometchtech <kometch@gmail.com>
WORKDIR /
ENV PDNS_REC_VERSION 4.1.1
ENV DEBIAN_FRONTEND noninteractive
ADD echo /bin/echo
RUN echo 'deb http://httpredir.debian.org/debian testing main' > /etc/apt/sources.list.d/testing.list 
RUN echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup
RUN apt-get update \
    && apt-get -qq install -y --no-install-recommends apt-utils \
    && apt-get -y -qq install --no-install-recommends \
      pdns-recursor/testing 
WORKDIR /pdns-recursor-${PDNS_REC_VERSION}
RUN rm -rf /var/lib/apt/lists/*
WORKDIR /etc/powerdns
#RUN mv recursor.conf-dist recursor.conf
VOLUME ["/etc/powerdns"]
EXPOSE 53 53/udp
ENTRYPOINT ["/usr/sbin/pdns_recursor", "--daemon=no", "--write-pid=no", "--disable-syslog", "--log-timestamp=yes"]
