FROM arm64v8/alpine:latest
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64" \
      description="BIND9 for Aarch64"

# Environment
ENV VERSION="9.13.3" \
    TZ=Asia/Tokyo
ARG BUILD_PKGS="build-base curl automake autoconf libressl-dev libcap-dev perl linux-headers bsd-compat-headers libxml2-dev json-c-dev libedit-dev readline-dev ncurses-dev gawk"
ARG RUN_PKGS=" protobuf-c tzdata libxml2 json-c libedit libressl libcap"
ARG CFLAGS="-Os -pipe -fomit-frame-pointer -mtune=native -march=native"
ARG LDFLAGS="-Wl,-z -Wl,relro -Wl,-z -Wl,now -Wl,--as-needed"

# dev package install
RUN apk add --update --upgrade apk-tools \
  && apk add --update --no-cache --virtual .build-deps ${BUILD_PKGS} \
  && apk add --no-cache ${RUN_PKGS} \
## build
  && cd / \
  && mkdir -p /usr/src \
  && curl -L https://ftp.isc.org/isc/bind9/${VERSION}/bind-${VERSION}.tar.gz -o bind9.tar.gz \
  && tar xf bind9.tar.gz --strip-components=1 -C /usr/src \
  && rm bind9.tar.gz \
  && cd /usr/src \
  \
  && ./configure \
    --prefix=/usr/local \
    --sysconfdir=/etc/named \
    --localstatedir=/var \
    --with-libtool \
    --with-openssl \
    --with-tuning=default \
    --with-make-clean \
    --with-libxml2 \
    --with-libjson \
    --enable-largefile \
    --enable-fixed-rrset \
    --enable-dnsrps \
    --enable-shared \
    --enable-static \
    CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
    && make -j "$(nproc)" \
  && make install \
  ## cleanup
  && cd / \
# add user
  && adduser -DH named \
  && mkdir -p /var/named /var/run/named \
  && chown -R named:named /var/named /var/run/named \
# download named.root 
  && curl -L https://www.internic.net/domain/named.root -o /var/named/named.ca \
# Trim down the image
  && apk del --purge .build-deps \
  && rm -rf /usr/src/* /var/cache/apk/* /tmp/build 

# Select entrypoint
EXPOSE 53/tcp 53/udp
CMD ["named", "-c", "/etc/named/named.conf", "-g", "-u", "named"]

