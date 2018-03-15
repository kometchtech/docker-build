# Environment
FROM arm64v8/debian:9.3-slim
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64"
ENV UNBOUND_VERSION 1.7.0
ENV DEBIAN_FRONTEND noninteractive
ENV BUILD_PKGS build-essential curl automake autoconf libexpat1-dev
ENV RUN_PKGS openssl libevent-2.0-5 libssl-dev libevent-dev ca-certificates ldnsutils
ENV TZ Asia/Tokyo

# source build and install
WORKDIR /usr/local/etc
RUN echo $TZ > /etc/timezone \
    && apt-get update \
    && apt-get -qq install -y --no-install-recommends $BUILD_PKGS $RUN_PKGS \
    && curl -fLO "https://www.unbound.net/downloads/unbound-${UNBOUND_VERSION}.tar.gz" \
    && tar xf "unbound-${UNBOUND_VERSION}.tar.gz" \
    && rm -f "unbound-${UNBOUND_VERSION}.tar.gz" \ 
    && cd unbound-${UNBOUND_VERSION} \
    && ./configure \
      --prefix=/usr/local \
      --with-libevent \
      --with-pthreads \
      --with-ssl \
      --disable-rpath \
      --sysconfdir=/etc/unbound \
      --with-conf-file=/etc/unbound/unbound.conf \
      --with-pidfile=/var/run/unbound.pid \
      --enable-sha2 \
      --disable-gost \
      --disable-ecdsa \
      --enable-pie \
      --disable-flto \
      --enable-relro-now \
      CFLAGS='-fPIC -Os -pipe' \
      CXXFLAGS=${LDFLAGS} \
	  && make -j "$(nproc)" \
    && make install \
    && rm -rf \
        "/usr/local/etc/unbound-${UNBOUND_VERSION}" \
        /var/lib/apt/lists/* \
        /usr/local/share/man \
    && apt-get purge --auto-remove -y $BUILD_PKGS \
    && useradd -s /usr/sbin/nologin -d /etc/unbound unbound \
    && chown -R unbound:unbound /etc/unbound \
    && ln -snf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# Application execution related information
ADD ./run.sh /usr/local/sbin/
RUN ["chmod", "+x", "/usr/local/sbin/run.sh"]
VOLUME ["/etc/unbound"]

# export TCP and UDP
EXPOSE 53/tcp 53/udp 
CMD ["/usr/local/sbin/run.sh"]
