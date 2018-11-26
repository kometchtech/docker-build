FROM arm64v8/alpine:latest AS build

ARG VERSION=1.4.2
ENV BUILD_PKGS "build-base curl git libtool m4 yaml-dev autoconf automake linux-headers gawk libressl-dev \
                libuv-dev libev-dev check-dev libidn-dev unbound "
ARG CFLAGS="-O2 -fstack-protector -pthread -fomit-frame-pointer -pipe "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"

WORKDIR /usr/local
RUN apk add --update --no-cache ${BUILD_PKGS} ${RUN_PKGS} \
    && git clone -b v${VERSION} --depth 1 https://github.com/getdnsapi/getdns.git \
    && cd getdns \
    && git submodule update --init \
    && libtoolize -ci \
    && autoreconf -if \
    && mkdir build \
    && cd build \
    && ../configure \
    --without-libidn2 \
    --enable-stub-only \
    --with-stubby \
    --with-libuv \
    --with-libev \
    CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" CXXFLAGS="${CFLAGS}" \
    && make -j"$(nproc)" install DESTDIR=/tmp/root \
    && ldconfig / || true 

# Copy libgetdns, libgetdns_ext_ev, libgetdns_ext_uv
RUN mkdir -p /tmp/root/var/stubby /tmp/root/etc/stubby \
    && cp -r /usr/local/lib/* /tmp/root/usr/local/lib/ \
    && rm -rf /tmp/root/var/run /tmp/root/usr/local/share/man/* \
    && unbound-anchor -v -a "/tmp/root/etc/stubby/root.key" || true

# copy example conf
RUN curl -fSL https://raw.githubusercontent.com/getdnsapi/stubby/develop/stubby.yml.example \
         -o /tmp/root/etc/stubby/stubby.yml 


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ENV RUN_PKGS "tzdata yaml libressl libuv libidn libev "
RUN apk add --no-cache ${RUN_PKGS} \
RUN rm -rf /var/cache/apk/* /usr/local/share/man/* \
    && mkdir -p /etc/stubby


# Final container
FROM runtime
LABEL MAINTAINER "kometchtech <kometch@gmail.com>" \
      url="https://dnsprivacy.org/wiki/display/DP/DNS+Privacy+Daemon+-+Stubby" \
      description="Stubby is the name given to a mode of using getdns which enables \
                   it to act as a local DNS Privacy stub resolver (using DNS-over-TLS)."

ENV TZ Asia/Tokyo

# export DNS over UDP
EXPOSE 53/UDP 53/TCP

# select ENTRYPOINT
CMD ["/usr/local/bin/stubby", "-C", "/etc/stubby/stubby.yml"]

COPY --from=build /tmp/root/ /
RUN ldconfig / || true
