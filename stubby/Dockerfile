FROM arm64v8/alpine:edge
LABEL MAINTAINER "kometchtech <kometch@gmail.com>" \
      url "https://dnsprivacy.org/wiki/display/DP/DNS+Privacy+Daemon+-+Stubby" \
      description "Stubby is the name given to a mode of using getdns which enables it to act as a local DNS Privacy stub resolver (using DNS-over-TLS)."

ARG VERSION=1.4.2
ENV TZ="Asia/Tokyo"
ARG BUILD_PKGS="build-base curl git libtool m4 yaml-dev autoconf automake linux-headers gawk libressl-dev libuv-dev libev-dev check-dev gawk"
ARG RUN_PKGS="tzdata yaml libressl unbound"
ARG CFLAGS="-Os -fstack-protector -pthread -fomit-frame-pointer -pipe -march=armv8-a+crc -mtune=cortex-a53 -ffast-math "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"

WORKDIR /usr/local
RUN sed -i -e 's/v[[:digit:]]\.[[:digit:]]/edge/g' /etc/apk/repositories \
    && apk add --no-cache libressl \
    && apk add --update --no-cache ${BUILD_PKGS} ${RUN_PKGS} \
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
    && make -j"$(nproc)" install \
    && wget https://raw.githubusercontent.com/getdnsapi/stubby/develop/stubby.yml.example \
            -O /usr/local/etc/stubby/stubby.yml \
    && apk del --purge ${BUILD_PKGS} \
    && rm -rf /var/cache/apk/* /var/tmp* \
    && cd / \
    && rm -rf /usr/local/getdns \
    && unbound-anchor -v -a "/etc/unbound/root.key" || logger "Please check root.key"

# export DNS over UDP
EXPOSE 53

# select ENTRYPOINT
CMD ["/usr/local/bin/stubby", "-C", "/usr/local/etc/stubby/stubby.yml"]
