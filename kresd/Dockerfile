# Intermediate container for Knot DNS build (not persistent)
FROM arm64v8/alpine:latest AS knot-dns-build

# Environment
ARG KNOT_DNS_VERSION="2.8.2"
# Build dependencies
ARG KNOT_DNS_BUILD_DEPS="build-base clang automake autoconf libtool pkgconfig userspace-rcu-dev gnutls curl \
                        gawk git bsd-compat-headers musl-utils fstrm-dev@test protobuf-c-dev protobuf-dev "
ENV KNOT_RESOLVER_BUILD_DEPS="build-base clang automake autoconf libtool pkgconfig git luajit-dev libuv-dev \
                              lua-compat53 gnutls-dev fstrm-dev@test jansson-dev userspace-rcu-dev curl vim \
                              bsd-compat-headers nettle-dev binutils cmocka-dev protobuf-c-dev protobuf-dev \
                              lua5.1-sec lua5.1-socket lua5.1-filesystem libedit-dev meson lmdb-dev "
ARG BUILDENV_DEPS="${KNOT_DNS_BUILD_DEPS} ${KNOT_RESOLVER_BUILD_DEPS}"
ARG CFLAGS="-std=gnu99 -O2 -pthread -pipe -fPIC -fPIC -fPIE -D_GNU_SOURCE "
ARG CXXFLAGS="${CFLAGS} "
ARG LDFLAGS="-Wl,--export-dynamic -Wl,-z,relro -Wl,-z,now "
ARG CC="clang"
ARG CXX="clang++"

# Install dependencies and sources
RUN echo "@test http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
RUN apk add --update ${BUILDENV_DEPS}
# Install Knot DNS from sources
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
ARG KNOT_RESOLVER_RUNTIME_DEPS="lmdb luajit libuv lua5.1-sec lua5.1-socket lua5.1-filesystem lua-compat53 \
                               ca-certificates musl-utils tzdata libstdc++ jansson nettle protobuf-c libedit "
ARG KNOT_RESOLVER_RUNTIME_DEPS_HTTP="lua5.1-http lua5.1-maxminddb "
ARG KNOT_RESOLVER_RUNTIME_DEPS_EXTRA="fstrm@test lua5.1-cqueues "
ARG KNOT_RESOLVER_RUNTIME_DEPS_SSL="ca-certificates openssl "
ARG RUNTIME_DEPS="${KNOT_DNS_RUNTIME_DEPS} ${KNOT_RESOLVER_RUNTIME_DEPS} ${KNOT_RESOLVER_RUNTIME_DEPS_HTTP} \
                  ${KNOT_RESOLVER_RUNTIME_DEPS_EXTRA} ${KNOT_RESOLVER_RUNTIME_DEPS_SSL} "

RUN echo "@test http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
    && apk add --update --no-cache ${RUNTIME_DEPS} \
    && rm -rf /var/cache/apk/* /usr/local/share/man/* \
    && mkdir -p /var/run/knot-resolver \
    && update-ca-certificates

# Intermediate container for Knot Resolver build
FROM knot-dns-build AS build

# Build Knot Resolver
# Environmet
ARG VERSION="4.0.0"
ARG CFLAGS="-std=gnu99 -O2 -pthread -pipe -fPIC -fPIC -fPIE -D_GNU_SOURCE "
ARG CXXFLAGS="${CFLAGS} "
ARG LDFLAGS="-Wl,--export-dynamic -Wl,-z,relro -Wl,-z,now "

# Knot Resolver build
RUN mkdir -p /tmp/root/etc/knot-resolver
RUN git clone -b v${VERSION} --depth=1 --recursive https://github.com/CZ-NIC/knot-resolver.git /tmp/knot-resolver

RUN cd /tmp/knot-resolver \
    && CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" meson build_docker --buildtype=plain --prefix=/usr --libdir=lib -Dc_args="${CFLAGS}" \
#    && CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" meson build_docker --buildtype=release --prefix=/usr --libdir=lib \
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

ENTRYPOINT ["/usr/local/sbin/run.sh"]
CMD ["-c", "/etc/knot-resolver/kresd.conf"]

# Fetch Knot Resolver + Knot DNS libraries from build image
COPY --from=build /tmp/root/ /
COPY ./run.sh /usr/local/sbin/run.sh
RUN chmod +x /usr/local/sbin/run.sh \
    && ldconfig /
