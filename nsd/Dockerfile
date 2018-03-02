# Environment
FROM arm64v8/debian:9.3-slim
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64"
ENV NSD_VERSION 4.1.20
ENV DEBIAN_FRONTEND noninteractive
ENV BUILD_PKGS build-essential curl automake autoconf
ENV RUN_PKGS openssl libevent-2.0-5 libssl-dev libevent-dev ca-certificates ldnsutils
ENV TZ Asia/Tokyo

# source build and install
WORKDIR /usr/local/etc
RUN echo $TZ > /etc/timezone \
    && apt-get update \
    && apt-get -qq install -y --no-install-recommends $BUILD_PKGS $RUN_PKGS \
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
        "/usr/local/etc/nsd-${NSD_VERSION}" \
        /var/lib/apt/lists/* \
        /usr/local/share/man \
    && apt-get purge --auto-remove -y $BUILD_PKGS \
    && useradd -s /usr/sbin/nologin -d /usr/local/etc/nsd nsd \
    && mkdir -p /var/cache/nsd /var/run/nsd /usr/local/etc/nsd/zones \
    && chown -R nsd:nsd /usr/local/var/db/nsd /usr/local/etc/nsd /var/run/nsd /var/cache/nsd \
    && chmod 0700 /usr/local/var/db/nsd /var/run/nsd /var/cache/nsd \
    && ln -snf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# Application execution related information
COPY conf /usr/local/sbin
VOLUME ["/usr/local/etc/nsd", "/usr/local/etc/nsd/zones", "/usr/local/var/db/nsd"]

# export TCP and UDP
EXPOSE 53/tcp 53/udp 8952/tcp
RUN ["chmod", "+x", "/usr/local/sbin/run.sh"]
#CMD ["/usr/local/sbin/nsd", "-d", "-p", "/var/run/nsd.pid"]
CMD ["/usr/local/sbin/run.sh"]
