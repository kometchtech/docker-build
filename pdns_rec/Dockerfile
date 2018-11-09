FROM arm64v8/alpine:edge
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64" \
      description="PowerDNS recursor for Aarch64"

# Environmet
ENV TZ=Asia/Tokyo
ARG VERSION=4.1.7
ARG BUILD_PKGS="build-base libressl-dev boost-dev lua5.3-dev libedit-dev libsodium-dev protobuf-dev curl gawk"
ARG RUN_PKGS="tzdata"
ARG CFLAGS="-Os -fstack-protector -pthread -fomit-frame-pointer -pipe -mtune=generic "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-s,-flto,--gc-sections,-z -Wl,relro -Wl,-z -Wl,now -Wl,--as-needed"

# Select entrypoint
EXPOSE 53/tcp 53/udp
VOLUME ["/etc/powerdns"]
CMD ["/usr/local/sbin/pdns_recursor", "--disable-syslog", "--log-timestamp=yes"]

# dev package install
RUN sed -i -e 's/v[[:digit:]]\.[[:digit:]]/edge/g' /etc/apk/repositories \
#  && apk add --update --upgrade apk-tools \
  && apk --update add --no-cache --virtual build-deps ${BUILD_PKGS} \
  && mkdir -p /usr/src \
## build
  && cd / \
  && curl -sfL https://downloads.powerdns.com/releases/pdns-recursor-${VERSION}.tar.bz2 -o pdns-recursor.tar.bz2 \
  && tar xf pdns-recursor.tar.bz2 --strip-components=1 -C /usr/src \
  && rm pdns-recursor.tar.bz2 \
  && cd /usr/src \
  && CFLAGS=${CFLAGS} CXXFLAGS=${CXXFLAGS} LDFLAGS=${LDFLAGS} ./configure \
    --prefix=/usr/local \
    --sysconfdir=/etc/powerdns \
    --localstatedir=/var \
    --libdir=${prefix}/lib/aarch64-linux-gnu \
    --libexecdir=${prefix}/lib/aarch64-linux-gnu \
    --enable-unit-tests \
    --disable-static \
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
  && apk del --purge build-deps \
  && rm -rf /var/cache/apk/* /tmp/build \
  && adduser -DH pdnsrec
