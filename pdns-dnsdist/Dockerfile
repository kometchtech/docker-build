FROM arm64v8/alpine:edge
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64" \
      description="dnsdist for Aarch64"

# Env
ENV TZ=Asia/Tokyo
ARG VERSION=1.3.0
ARG BUILD_PKGS="g++ make libressl boost-dev lua5.3-dev libedit-dev libsodium-dev protobuf-dev re2-dev"
ARG RUN_PKGS=""

# Select entrypoint
USER _dnsdist
EXPOSE 53/tcp 53/udp
VOLUME ["/etc/dnsdist"]
ENTRYPOINT ["dnsdist", "--supervised", "--disable-syslog", "-u", "_dnsdist", "-g", "_dnsdist"]

# dev package install
RUN apk add --no-cache --virtual .build-deps ${BUILD_PKGS} \
  && mkdir -p /usr/src \
## build
  && cd / \
  && wget -O dnsdist.tar.bz2 https://downloads.powerdns.com/releases/dnsdist-$VERSION.tar.bz2 \
  && tar xf dnsdist.tar.bz2 --strip-components=1 -C /usr/src \
  && rm dnsdist.tar.bz2 \
  && cd /usr/src \
  \
  && CFLAGS='-Os' CXXFLAGS='-Os' ./configure \
    --prefix=/usr/local \
    --sysconfdir=/etc/dnsdist \
    --localstatedir=/var \
    --enable-libsodium \
    --enable-dnscrypt \
    --enable-re2 \
    --disable-static \
  && make -j "$(nproc)" \
  && make install \
## cleanup
  && cd / \
  && rm -rf /usr/src \
  \
  && runDeps="$( \
    scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
      | tr ',' '\n' \
      | sort -u \
      | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
  )" \
  && apk add --virtual .rundeps $runDeps \
  && apk del --purge .build-deps \
  && rm -rf /var/cache/apk/* /tmp/build \
  && adduser -DH _dnsdist
