# Environment
FROM arm64v8/debian:9.3
LABEL maintainer="kometchtech <kometch@gmail.com>"
ENV NSD_VERSION 4.1.20
ENV DEBIAN_FRONTEND noninteractive

# Application execution related information
VOLUME ["/usr/local/etc/nsd"]
EXPOSE 53/TCP 53/UDP 8952/TCP
CMD ["/usr/local/sbin/nsd", "-d"]

# source build and install
WORKDIR /usr/local/etc/nsd
RUN apt-get update \
    && apt-get -qq install --no-install-recommends \
      openssl \
      libevent-2.0-5 \
      build-essential \
      libssl-dev \
      libevent-dev \
      coreutils \
      curl \
      automake \
      autoconf \
    && curl -fSL "http://www.nlnetlabs.nl/downloads/nsd/nsd-${NSD_VERSION}.tar.gz" -o "nsd-${NSD_VERSION}.tar.gz" \
    && tar xf "nsd-${NSD_VERSION}.tar.gz" \
    && rm -f "nsd-${NSD_VERSION}.tar.gz" 
WORKDIR nsd-${NSD_VERSION}
RUN autoreconf -if \
  && ./configure \
      --prefix=/usr/local \
      --with-zonesdir=/usr/local/etc/nsd/zones \
      --with-libevent \
      --with-ssl \
      --enable-ratelimit \
      --enable-packed \
	&& make -j "$(nproc)" \
  && make install \
  && rm -rf \
      "nsd-${NSD_VERSION}" \
      /var/lib/apt/lists/* \
  && apt-get clean \
  && apt-get autoremove -y \
  && useradd -s /usr/sbin/nologin -d /usr/local/etc/nsd nsd \
  && chown nsd:nsd /usr/local/var/db/nsd \
  && chmod 0700 /usr/localvar/db/nsd
  && cd /usr/local/etc/nsd
  && mv nsd.conf.sample nsd.conf