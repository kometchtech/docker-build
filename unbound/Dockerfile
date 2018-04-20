
FROM arm64v8/debian:9.3-slim
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64"

# Environment
ARG UNBOUND_VERSION=1.7.0
ARG DEBIAN_FRONTEND=noninteractive
ARG BUILD_PKGS="build-essential curl automake autoconf libexpat1-dev libssl-dev libevent-dev"
ARG RUN_PKGS="openssl libevent-2.0-5 ca-certificates ldnsutils"
ENV TZ=Asia/Tokyo

# source build and install
WORKDIR /usr/local/etc
RUN echo $TZ > /etc/timezone \
    && apt-get update \
    && apt-get -qq install -y --no-install-recommends ${BUILD_PKGS} ${RUN_PKGS} \
    && mkdir -p /usr/src \
    && curl -fL "https://www.unbound.net/downloads/unbound-${UNBOUND_VERSION}.tar.gz" -o unbound.tar.gz \
    && tar xf "unbound.tar.gz" --strip-components=1 -C /usr/src \
    && rm -f "unbound.tar.gz" \ 
    && cd /usr/src \
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
      CFLAGS='-fPIC -O3 -pipe -mtune=native -march=native' \
      CXXFLAGS=${CFLAGS} \
	  && make -j "$(nproc)" \
    && make install \
    && rm -rf /usr/src \
        /usr/local/share/man \
    && apt-get purge --auto-remove -y ${BUILD_PKGS} \
    && rm -rf /var/lib/apt/* \
    && useradd -s /usr/sbin/nologin -d /etc/unbound unbound \
    && chown -R unbound:unbound /etc/unbound \
    && ln -snf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# Application execution related information
USER unbound
ADD ./run.sh /usr/local/sbin/
RUN ["chmod", "+x", "/usr/local/sbin/run.sh"]
VOLUME ["/etc/unbound"]

# export TCP and UDP
EXPOSE 53/tcp 53/udp 
CMD ["/usr/local/sbin/run.sh"]
