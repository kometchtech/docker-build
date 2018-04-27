FROM arm64v8/alpine:edge
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64"

# Environment
ARG UNBOUND_VERSION=1.7.1rc1
ARG BUILD_PKGS="build-base curl git yaml-dev openssl-dev libtool m4 autoconf automake linux-headers"
ARG RUN_PKGS="tzdata"
ARG CFLAGS="-fPIE -DPIE -Os -fomit-frame-pointer -pipe"
ARG CFLAGS="-fPIE -DPIE -Os -fomit-frame-pointer -pipe"
ARG CXXFLAGS="-fPIE -DPIE -Os -fomit-frame-pointer -pipe"
ARG LDFLAGS="-Wl,-z -Wl,relro -Wl,-z -Wl,now -Wl,--as-needed"
ENV TZ Asia/Tokyo

# source build and install
RUN apk add --update --no-cache ${BUILD_PKGS} ${RUN_PKGS} \
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
        CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" CXXFLAGS="${CFLAGS}" \
    && make -j$(nproc) \
    && make install \
    && ldconfig \
    && apk del --purge ${BUILD_PKGS} \
    && rm -rf /var/cache/apk/* 

COPY stubby.yaml /usr/local/etc/stubby/stubby.yml

# export TCP and UDP
EXPOSE 8053
CMD [ "/usr/local/bin/stubby" ]
