FROM arm64v8/alpine:edge
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64" \
      description="dnsdist for Aarch64"

# Env
ENV TZ=Asia/Tokyo \
    VERSION="1.3.0"
ARG BUILD_PKGS="build-base libressl-dev boost-dev lua5.3-dev libsodium-dev protobuf-dev re2-dev net-snmp-dev ca-certificates openssl libedit-dev gawk"
ARG RUN_PKGS="tzdata"
ARG CFLAGS="-fPIC -fPIE -DPIE -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 --param ssp-buffer-size=4 -fstack-protector -Os -fomit-frame-pointer -pipe"
ARG CPPFLAGS="-Os -fomit-frame-pointer -pipe"
ARG CXXFLAGS="-fPIC -fPIE -DPIE -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 --param ssp-buffer-size=4 -fstack-protector -Os -fomit-frame-pointer -pipe"
ARG LDFLAGS="-Wl,-z -Wl,relro -Wl,-z -Wl,now -Wl,--as-needed"

# Select entrypoint
EXPOSE 53/tcp 53/udp
VOLUME ["/etc/dnsdist"]
ENTRYPOINT ["dnsdist", "--supervised", "--disable-syslog", "-u", "_dnsdist", "-g", "_dnsdist"]

# dev package install
RUN sed -i -e "s/3.7/3.8/" /etc/apk/repositories \
  && apk add --update --upgrade apk-tools \
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
    --enable-re2 \
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
&& adduser -DH _dnsdist
