FROM arm64v8/alpine:edge
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64" \
      description="dnsdist for Aarch64"

# Env
ENV TZ=Asia/Tokyo \
    VERSION="1.3.3"
ARG BUILD_PKGS="build-base boost-dev lua5.3-dev libsodium-dev protobuf-dev re2-dev net-snmp-dev ca-certificates openssl libedit-dev gawk fstrm-dev gnutls-dev libressl-dev"
ARG RUN_PKGS="tzdata"
ARG CFLAGS="-fPIC -fPIE -DPIE -Ofast -fstack-protector -pthread -fomit-frame-pointer -pipe -mtune=generic "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"

# Select entrypoint
EXPOSE 53/tcp 53/udp
VOLUME ["/etc/dnsdist"]
ENTRYPOINT ["dnsdist", "--supervised", "--disable-syslog", "-u", "dnsdist", "-g", "dnsdist"]

# dev package install
RUN sed -i -e 's/v[[:digit:]]\.[[:digit:]]/edge/g' /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
#  && apk add --update --upgrade apk-tools \
  && apk add --update ${RUN_PKGS} \ 
  && apk add --virtual .build-deps ${BUILD_PKGS} \
  && update-ca-certificates \
  && mkdir -p /usr/src \
## build
  && cd / \
  && wget https://downloads.powerdns.com/releases/dnsdist-${VERSION}.tar.bz2 -O dnsdist.tar.bz2 \
  && tar xf dnsdist.tar.bz2 --strip-components=1 -C /usr/src \
  && rm dnsdist.tar.bz2 \
  && cd /usr/src \
  \
  && ./configure \
    --prefix=/usr/local \
    --sysconfdir=/etc/dnsdist \
    --localstatedir=/var \
    --enable-libsodium \
    --enable-dnscrypt \
    --enable-dns-over-tls \
    --enable-re2 \
    --with-protobuf=yes \
    --with-luajit \
    --disable-static \
    CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
  && make -j2  \
  && make install-strip \
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
  && adduser -DH dnsdist
