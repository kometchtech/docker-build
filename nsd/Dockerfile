# Environment
FROM arm64v8/debian:9.3-slim
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64"
ENV NSD_VERSION 4.1.20
ENV DEBIAN_FRONTEND noninteractive
ENV BUILD_PKGS build-essential coreutils curl automake autoconf
ENV RUN_PKGS openssl libevent-2.0-5 libssl-dev libevent-dev

# Application execution related information
VOLUME ["/usr/local/etc/nsd"]
EXPOSE 53/TCP 53/UDP 8952/TCP
CMD ["/usr/local/sbin/nsd", "-d"]

# source build and install
WORKDIR /usr/local/etc
RUN apt-get update \
    && apt-get -qq install --no-install-recommends $BUILD_PKGS $RUN_PKGS \
    && curl -fLO "http://www.nlnetlabs.nl/downloads/nsd/nsd-${NSD_VERSION}.tar.gz" \
    && tar xf "nsd-${NSD_VERSION}.tar.gz" \
    && rm -f "nsd-${NSD_VERSION}.tar.gz" \ 
    && cd nsd-${NSD_VERSION} \
    && autoreconf -if \
    && ./configure \
      --prefix=/usr/local \
      --with-zonesdir=/usr/local/etc/nsd/zones \
      --with-libevent \
      --with-ssl \
      --disable-flto \
      --enable-ratelimit \
      --enable-packed \
	  && make -j "$(nproc)" \
    && make install \
    && rm -rf \
        "nsd-${NSD_VERSION}" \
        /var/lib/apt/lists/* \
    && apt-get purge -y $BUILD_PKGS \
    && apt-get clean \
    && apt-get autoremove -y \
    && useradd -s /usr/sbin/nologin -d /usr/local/etc/nsd nsd \
    && chown nsd:nsd /usr/local/var/db/nsd \
    && chmod 0700 /usr/local/var/db/nsd \
    && mv /usr/local/etc/nsd/nsd.conf.sample /usr/local/etc/nsd/nsd.conf
