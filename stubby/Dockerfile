# syntax = docker/dockerfile:experimental
FROM arm64v8/alpine:latest AS getdns-build

ENV VERSION v1.5.2-rc1
ARG BUILD_PKGS="build-base clang git libtool m4 yaml-dev autoconf automake linux-headers gawk libressl-dev \
                libuv-dev libev-dev check-dev unbound-dev libcrypto1.1 "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIC -FORTIFY_SOURCE=2 -fPIE "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "
ENV CC="clang"
ENV CXX="clang++"

# build dependencies install
#RUN --mount=type=cache,target=/var/cache/apk \
RUN apk add --update ${BUILD_PKGS}
RUN mkdir -p /usr/src /tmp/root/var/stubby/ /tmp/root/etc/stubby/ /tmp/root/usr/local/lib/ /tmp/root/usr/local/include
# app build
RUN git clone -b ${VERSION} --depth 1 https://github.com/getdnsapi/getdns.git /usr/src
RUN cd /usr/src \
    && git submodule update --init \
    && libtoolize -ci \
    && autoreconf -if \
    && mkdir build \
    && cd build \
    && ../configure \
    --without-libidn \
    --without-libidn2 \
    --with-stubby \
    --with-libuv \
    --with-libev \
    CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" CXXFLAGS="${CFLAGS}" \
    && make -j"$(nproc)" install \
    && ldconfig /
# Copy libgetdns, libgetdns_ext_ev, libgetdns_ext_uv
RUN cp -r /usr/local/lib/* /tmp/root/usr/local/lib/ \
    && cp -r /usr/local/include/* /tmp/root/usr/local/include/ \
    && rm -rf /tmp/root/var/run /tmp/root/usr/local/share/man/*


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ENV RUN_PKGS "tzdata yaml libuv libev unbound-libs libressl2.7-libssl libressl2.7-libcrypto "
RUN apk add --update --no-cache ${RUN_PKGS} \
    && rm -rf /var/cache/apk/* /usr/local/share/man/*


# build stubby
FROM getdns-build AS build

ENV STUBBY_VERSION v0.2.5
ARG BUILD_PKGS="build-base clang autoconf automake gawk git yaml libressl unbound "

#RUN --mount=type=cache,target=/var/cache/apk \
RUN apk add --update ${BUILD_PKGS}
RUN mkdir -p /usr/src/stubby /tmp/root/etc/unbound
RUN git clone -b ${STUBBY_VERSION} --depth=1 https://github.com/getdnsapi/stubby.git /usr/src/stuby
RUN cd /usr/src/stubby \
    && autoreconf -fi \
    && ./configure CFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib " \
    && make -j "$(nproc)" \
    && make install DESTDIR=/tmp/root
RUN unbound-anchor -v -a "/tmp/root/etc/unbound/getdns-root.key" || true
# copy example conf
RUN cp /usr/src/stubby/stubby.yml.example /tmp/root/etc/stubby/stubby.yml


# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      url="https://dnsprivacy.org/wiki/display/DP/DNS+Privacy+Daemon+-+Stubby" \
      description="Stubby is the name given to a mode of using getdns which enables \
                   it to act as a local DNS Privacy stub resolver (using DNS-over-TLS)."

# Environment
ENV TZ Asia/Tokyo

# Publish port DNS over UDP
EXPOSE 53/UDP 53/TCP

# service running
STOPSIGNAL SIGTERM

# select ENTRYPOINT
WORKDIR /etc/stubby
CMD ["/usr/local/bin/stubby", "-C", "/etc/stubby/stubby.yml"]

COPY --from=build /tmp/root/ /
RUN ldconfig /
