FROM arm64v8/alpine:edge
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64"

# Environment
ARG BUILD_PKGS="build-base curl git libtool m4 yaml-dev autoconf automake linux-headers gawk libressl-dev libuv-dev libev-dev check-dev"
ARG RUN_PKGS="tzdata yaml libressl unbound"
ARG CFLAGS="-O0 -fomit-frame-pointer -pipe"
ARG CXXFLAGS="-O0 -fomit-frame-pointer -pipe"
ARG LDFLAGS="-Wl,-z -Wl,relro -Wl,-z -Wl,now -Wl,--as-needed"
ENV TZ Asia/Tokyo

# source build and install
RUN cd / \
    && apk add --update --no-cache ${BUILD_PKGS} ${RUN_PKGS} \
    && git clone https://github.com/getdnsapi/getdns.git \
    && cd getdns \
    && git checkout develop \
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
    && make -j$(nproc) \
    && make install \
    && wget https://raw.githubusercontent.com/getdnsapi/stubby/develop/stubby.yml.example -P /usr/local/etc/stubby/ \
    && apk del --purge ${BUILD_PKGS} \
    && rm -rf /var/cache/apk/* \
    && cd / \
    && rm -rf getdns

# trust anchor
RUN ["unbound-anchor"]

# export TCP and UDP
EXPOSE 53 53/udp
CMD [ "/usr/local/bin/stubby" ]
