# syntax = docker/dockerfile:experimental
# lua dependencies
FROM arm64v8/alpine:latest AS lua-build
ARG BUILD_LUAS="build-base lua-dev openssl-dev bsd-compat-headers luarocks m4 libpsl-dev "

RUN apk add --update ${BUILD_LUAS}
# lua build
RUN luarocks-5.1 install cqueues \
    && luarocks-5.1 install luaossl \
    && luarocks-5.1 install http \
    && luarocks-5.1 install mmdblua \
    && luarocks-5.1 install psl


# Intermediate container for Knot DNS build (not persistent)
FROM arm64v8/alpine:latest AS knot-dns-build
# Environment
ARG KNOT_DNS_VERSION="3.0.5"
# Build dependencies
ARG BUILD_BASE="alpine-sdk clang llvm lld gawk autoconf automake libtool "
ARG KNOT_DNS_BUILD_DEPS="${BUILD_BASE} pkgconfig userspace-rcu-dev gnutls bsd-compat-headers musl-utils \
                        fstrm-dev protobuf-c-dev protobuf-dev "
ENV KNOT_RESOLVER_BUILD_DEPS="${BUILD_BASE} luajit-dev libuv-dev lua5.1-compat53 gnutls-dev fstrm-dev jansson-dev \
                              userspace-rcu-dev nettle-dev cmocka-dev protobuf-c-dev protobuf-dev libedit-dev meson \
                              lmdb-dev libpsl-dev "
ARG BUILDENV_DEPS="${KNOT_DNS_BUILD_DEPS} ${KNOT_RESOLVER_BUILD_DEPS}"
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer -D_FORTIFY_SOURCE=2 "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "
ENV CC="clang" \
    CXX="clang++" \
    AR="llvm-ar" \
    NM="llvm-nm" \
    RANLIB="llvm-ranlib" \
    LD="ld.lld" \
    STRIP="llvm-strip"

# Install dependencies and sources
RUN apk add --update ${BUILDENV_DEPS}
# Install Knot DNS from sources
COPY --from=lua-build /usr/local/share/lua/5.1/ /usr/local/share/lua/5.1/
COPY --from=lua-build /usr/local/lib/lua/5.1/ /usr/local/lib/lua/5.1/
RUN git clone -b v${KNOT_DNS_VERSION} --depth=1 https://gitlab.labs.nic.cz/knot/knot-dns.git /tmp/knot-dns
RUN cd /tmp/knot-dns \
    && autoreconf -if \
    && ./configure \
     --disable-fastparser \
     --disable-documentation \
     --disable-daemon \
     --disable-utilities \
     --with-lmdb=no \
    && make -j"$(nproc)" install
RUN ldconfig /
# Copy libknot, libdnssec, libzscanner to runtime
RUN mkdir -p /tmp/root/usr/local/include /tmp/root/usr/local/lib /tmp/root/usr/local/lib/pkgconfig
RUN cp -r /usr/local/include/libknot /usr/local/include/libdnssec /usr/local/include/libzscanner /tmp/root/usr/local/include
RUN cp -r /usr/local/lib/libknot* /usr/local/lib/libdnssec* /usr/local/lib/libzscanner* /tmp/root/usr/local/lib
RUN cp -r /usr/local/lib/pkgconfig/libknot.pc /usr/local/lib/pkgconfig/libdnssec.pc /usr/local/lib/pkgconfig/libzscanner.pc /tmp/root/usr/local/lib/pkgconfig


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ARG KNOT_DNS_RUNTIME_DEPS="gnutls "
ARG KNOT_RESOLVER_RUNTIME_DEPS="lmdb luajit libuv lua5.1-compat53 \
                               ca-certificates musl-utils tzdata libstdc++ jansson nettle protobuf-c libedit \
                               tini libpsl "
ARG KNOT_RESOLVER_RUNTIME_DEPS_EXTRA="fstrm "
ARG KNOT_RESOLVER_RUNTIME_DEPS_SSL="ca-certificates openssl "
ARG RUNTIME_DEPS="${KNOT_DNS_RUNTIME_DEPS} ${KNOT_RESOLVER_RUNTIME_DEPS} ${KNOT_RESOLVER_RUNTIME_DEPS_HTTP} \
                  ${KNOT_RESOLVER_RUNTIME_DEPS_EXTRA} ${KNOT_RESOLVER_RUNTIME_DEPS_SSL} "

COPY --from=lua-build /usr/local/share/lua/5.1/ /usr/local/share/lua/5.1/
COPY --from=lua-build /usr/local/lib/lua/5.1/ /usr/local/lib/lua/5.1/
RUN apk add --update --no-cache ${RUNTIME_DEPS} \
    && rm -rf /var/cache/apk/* /usr/local/share/man/* \
    && mkdir -p /var/cache/knot-resolver \
    && update-ca-certificates

# Intermediate container for Knot Resolver build
FROM knot-dns-build AS build

# Build Knot Resolver
# Environmet
ARG VERSION="4.0.0"

# Knot Resolver build
RUN mkdir -p /tmp/root/etc/knot-resolver
RUN git clone -b v${VERSION} --depth=1 --recursive https://gitlab.nic.cz/knot/knot-resolver.git /tmp/knot-resolver
RUN cd /tmp/knot-resolver \
    && meson build_docker --buildtype=plain --prefix=/usr --libdir=lib -Dc_args="${CFLAGS}" \
    && DESTDIR=/tmp/root ninja -C build_docker install \
    && cp /tmp/root/usr/share/doc/knot-resolver/examples/config.docker /tmp/root/etc/knot-resolver/kresd.conf


# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      description="Knot DNS team's things are modified and used." \
      url="https://www.knot-resolver.cz"

# Environment
ENV TZ Asia/Tokyo

# publish port DNS over UDP & TCP, DNS-over-TLS
EXPOSE 53/UDP 53/TCP 853/TCP

# service running
STOPSIGNAL SIGTERM

# Fetch Knot Resolver + Knot DNS libraries from build image
COPY --from=build /tmp/root/ /
COPY ./entrypoint.sh /usr/local/sbin/entrypoint.sh
RUN chmod +x /usr/local/sbin/entrypoint.sh \
    && ldconfig /

# set entrypoint
ENTRYPOINT ["/sbin/tini", "-g", "--", "/usr/local/sbin/entrypoint.sh"]
CMD ["kresd", "-n", "-c", "/etc/knot-resolver/kresd.conf"]
