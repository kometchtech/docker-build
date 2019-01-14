FROM arm64v8/alpine:latest AS getdns-build

ENV VERSION v1.5.1
ARG BUILD_PKGS="build-base clang curl git libtool m4 yaml-dev autoconf automake linux-headers gawk libressl-dev \
                libuv-dev libev-dev check-dev unbound-dev lld "
#ARG CFLAGS="-O2 -fstack-protector -pthread -fomit-frame-pointer -pipe -FORTIFY_SOURCE=2 -fPIE -fPIC \
#            -ftree-vectorize -ftree-slp-vectorize "
ARG CFLAGS="-O4 -pthread -pipe -fPIC -fPIC -FORTIFY_SOURCE=2 -fPIE -fuse-ld=lld "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-O4 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now"
ENV CC=clang
ENV CXX=clang++

RUN apk add --update --no-cache ${BUILD_PKGS}
RUN mkdir -p /usr/src /tmp/root/var/stubby/ /tmp/root/etc/stubby/ /tmp/root/usr/local/lib/ /tmp/root/usr/local/include
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
#    --enable-stub-only \
    --with-stubby \
    --with-libuv \
    --with-libev \
    CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" CXXFLAGS="${CFLAGS}" \
    && make -j"$(nproc)" install \
    && ldconfig / || true
# Copy libgetdns, libgetdns_ext_ev, libgetdns_ext_uv
RUN cp -r /usr/local/lib/* /tmp/root/usr/local/lib/ \
    && cp -r /usr/local/include/* /tmp/root/usr/local/include/ \
    && rm -rf /tmp/root/var/run /tmp/root/usr/local/share/man/*
# copy example conf
RUN curl -fsSL https://raw.githubusercontent.com/getdnsapi/stubby/develop/stubby.yml.example \
         -o /tmp/root/etc/stubby/stubby.yml


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ENV RUN_PKGS "tzdata yaml libressl libuv libev unbound-libs "
RUN apk add --update --no-cache ${RUN_PKGS} \
RUN rm -rf /var/cache/apk/* /usr/local/share/man/*


# build stubby
FROM getdns-build AS build

ENV STUBBY_VERSION v0.2.5
ARG BUILD_PKGS="build-base clang autoconf automake gawk git yaml libressl unbound lld "

RUN apk add --update --no-cache ${BUILD_PKGS}
RUN mkdir -p /usr/src/stubby /tmp/root/etc/unbound
RUN git clone -b ${STUBBY_VERSION} --depth=1 https://github.com/getdnsapi/stubby.git /usr/src/stuby
RUN cd /usr/src/stubby \
    && autoreconf -fi \
    && ./configure CFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib -fuse-ld=lld" \
    && make -j "$(nproc)" \
    && make install DESTDIR=/tmp/root
RUN mkdir -p /tmp/root/etc/unbound
RUN unbound-anchor -v -a "/tmp/root/etc/unbound/getdns-root.key" || true


# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      url="https://dnsprivacy.org/wiki/display/DP/DNS+Privacy+Daemon+-+Stubby" \
      description="Stubby is the name given to a mode of using getdns which enables \
                   it to act as a local DNS Privacy stub resolver (using DNS-over-TLS)."

# Environment
ENV TZ Asia/Tokyo

# export DNS over UDP
EXPOSE 53/UDP 53/TCP

# select ENTRYPOINT
WORKDIR /etc/stubby
CMD ["/usr/local/bin/stubby", "-C", "/etc/stubby/stubby.yml"]

COPY --from=build /tmp/root/ /
RUN ldconfig / || true
