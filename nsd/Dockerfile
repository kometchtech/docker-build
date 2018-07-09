FROM arm64v8/alpine:edge
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64"

# Environment
ARG NSD_VERSION=4.1.22
ARG BUILD_PKGS="build-base curl automake autoconf expat-dev libressl-dev libevent-dev"
ARG RUN_PKGS="libressl libevent ca-certificates ldns-tools tzdata"
ARG CFLAGS="-O2 -fPIC -pipe -mtune=native -march=native"
ARG LDFLAGS=""
ENV TZ=Asia/Tokyo

# source build and install
WORKDIR /usr/src/etc
RUN sed -i -e "s/3.7/3.8/" /etc/apk/repositories \
    && apk add --update --upgrade apk-tools \
    && apk add --update ${BUILD_PKGS} ${RUN_PKGS} \
    && mkdir -p /usr/src \
    && curl -fL "https://www.nlnetlabs.nl/downloads/nsd/nsd-${NSD_VERSION}.tar.gz" -o nsd.tar.gz \
    && tar xf "nsd.tar.gz" --strip-components=1 -C /usr/src \
    && rm -f "nsd.tar.gz" \ 
    && cd /usr/src \
    && autoreconf -vi \
    && ./configure \
      --prefix=/usr/local \
      --with-zonesdir=/usr/local/etc/nsd/zones \
      --with-libevent \
      --with-ssl \
      --disable-flto \
      --enable-ratelimit \
      --enable-packed \
      CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
	&& make  \
    && make install \
    && cd / \
    && rm -rf /usr/src \
    && apk del --purge ${BUILD_PKGS} \
    && rm -rf /var/cache/apk/* /usr/local/share/man \
    && adduser -DH nsd \
    && mkdir -p /var/cache/nsd /var/run/nsd /usr/local/etc/nsd/zones \
    && chmod 0700 /usr/local/var/db/nsd /var/run/nsd /var/cache/nsd 

# Application execution related information
COPY conf /usr/local/sbin
VOLUME ["/usr/local/etc/nsd", "/usr/local/etc/nsd/zones", "/usr/local/var/db/nsd"]

# export TCP and UDP
EXPOSE 53/tcp 53/udp 8952/tcp
RUN ["chmod", "+x", "/usr/local/sbin/run.sh"]
CMD ["/usr/local/sbin/run.sh"]
