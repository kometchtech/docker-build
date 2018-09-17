FROM arm64v8/alpine:latest
LABEL MAINTAINER "kometchtech <kometch@gmail.com>"

ARG VERSION=1.4.2
ARG BUILD_PKGS="build-base curl git libtool m4 yaml-dev autoconf automake linux-headers gawk libressl-dev libuv-dev libev-dev check-dev gawk"
ARG RUN_PKGS="tzdata yaml libressl unbound"
ARG CFLAGS="-Os -fomit-frame-pointer -pipe -flto -mtune=native -march=native"
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-z -Wl,relro -Wl,-z -Wl,now -Wl,--as-needed"
ENV TZ="Asia/Tokyo"

WORKDIR /usr/local
RUN apk add --update --no-cache ${BUILD_PKGS} ${RUN_PKGS} \
    && git clone -b v${VERSION} https://github.com/getdnsapi/getdns.git \
    && cd getdns \
    && git submodule update --init \
    && libtoolize -ci \
    && autoreconf -fi \
    && mkdir build \
    && cd build \
    && ../configure \
    --without-libidn \
    --without-libidn2 \
    --enable-stub-only \
    --with-stubby \
    --with-libuv \
    --with-libev \
    CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" CXXFLAGS="${CFLAGS}" \
    && make -j"$(nproc)" \
    && make install \
    && wget https://raw.githubusercontent.com/getdnsapi/stubby/develop/stubby.yml.example -P /usr/local/etc/stubby/ \
    && apk del --purge ${BUILD_PKGS} \
    && rm -rf /var/cache/apk/* /var/tmp* \
    && cd / \
    && rm -rf /usr/local/getdns \
    && unbound-anchor -v -a "/etc/unbound/root.key" || logger "Please check root.key"

COPY stubby.yml /usr/local/etc/stubby/stubby.yml

EXPOSE 53

CMD ["/usr/local/bin/stubby", "-C", "/usr/local/etc/stubby/stubby.yml"]
