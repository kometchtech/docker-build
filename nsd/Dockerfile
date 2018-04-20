# Environment
FROM arm64v8/alpine:edge
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64"
ENV NSD_VERSION 4.1.20
ENV DEBIAN_FRONTEND noninteractive
ENV BUILD_PKGS build-base curl automake autoconf expat-dev libressl-dev libevent-dev
ENV RUN_PKGS libressl libevent ca-certificates ldns-tools
ENV CFLAGS "-O3 -fPIC -mtune=native -march=native"
ENV LDFLAGS ""
ENV TZ Asia/Tokyo

# source build and install
WORKDIR /usr/local/etc
RUN echo $TZ > /etc/timezone \
    && apk add --no-cache ${BUILD_PKGS} ${RUN_PKGS} \
    && mkdir -p /usr/src \
    && curl -fL "http://www.nlnetlabs.nl/downloads/nsd/nsd-${NSD_VERSION}.tar.gz -o nsd.tar.gz" \
    && tar xf "nsd.tar.gz" --strip-components=1 -C /usr/src \
    && rm -f "nsd.tar.gz" \ 
    && cd /usr/src \
    && autoreconf -if \
    && ./configure \
      --prefix=/usr/local \
      --with-zonesdir=/usr/local/etc/nsd/zones \
      --with-libevent \
      --with-ssl \
      --disable-flto \
      --enable-ratelimit \
      --enable-packed \
      CFLAGS='${CFLAGS}' LDFLAGS='${LDFLAGS}' CXXFLAGS='${CFLAGS}' \
	&& make -j "$(nproc)" \
    && make install \
    && cd / \
    && rm -rf /usr/src \
    && apk del --purge ${BUILD_PKGS} \
    && rm -rf /var/cache/apk/* /usr/local/share/man \
    && addusr -DH nsd \
    && mkdir -p /var/cache/nsd /var/run/nsd /usr/local/etc/nsd/zones \
#    && chown -R nsd:nsd /usr/local/var/db/nsd /usr/local/etc/nsd /var/run/nsd /var/cache/nsd \
    && chmod 0700 /usr/local/var/db/nsd /var/run/nsd /var/cache/nsd \
    && ln -snf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# Application execution related information
COPY conf /usr/local/sbin
VOLUME ["/usr/local/etc/nsd", "/usr/local/etc/nsd/zones", "/usr/local/var/db/nsd"]

# export TCP and UDP
USER nsd
EXPOSE 53/tcp 53/udp 8952/tcp
RUN ["chmod", "+x", "/usr/local/sbin/run.sh"]
CMD ["/usr/local/sbin/run.sh"]
