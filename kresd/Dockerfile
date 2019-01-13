# Intermediate container for Knot DNS build (not persistent)
FROM arm64v8/alpine:latest AS knot-dns-build

# Environment
ENV KNOT_DNS_VERSION v2.7.5
# Build dependencies
ARG KNOT_DNS_BUILD_DEPS="build-base clang automake autoconf libtool pkgconfig userspace-rcu-dev \
			gnutls curl gawk git bsd-compat-headers musl-utils fstrm-dev@test protobuf-c-dev protobuf-dev "
ARG KNOT_RESOLVER_BUILD_DEPS="build-base clang automake autoconf libtool pkgconfig git luajit-dev libuv-dev lua-compat53 \
			gnutls-dev fstrm-dev@test jansson-dev userspace-rcu-dev curl vim bsd-compat-headers nettle-dev \
			binutils cmocka-dev protobuf-c-dev protobuf-dev lua5.1-sec lua5.1-socket lua5.1-filesystem libedit-dev "
ARG BUILDENV_DEPS="${KNOT_DNS_BUILD_DEPS} ${KNOT_RESOLVER_BUILD_DEPS}"
#ARG CFLAGS="-O2 -fstack-protector -pthread -heap-arrays -pipe -fPIC -FORTIFY_SOURCE=2 -fPIE \
#            -fomit-frame-pointer -ftree-vectorize -ftree-slp-vectorize "
ARG CFLAGS="-O4 -pthread -pipe -fPIC -fPIC -FORTIFY_SOURCE=2 -fPIE "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"
ARG CC=clang
ARG CXX=clang++

# Install dependencies and sources
RUN echo "@test http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk add --update --no-cache ${BUILDENV_DEPS}
# Install Knot DNS from sources
RUN git clone -b ${KNOT_DNS_VERSION} --depth=1 https://gitlab.labs.nic.cz/knot/knot-dns.git /tmp/knot-dns \
    && cd /tmp/knot-dns \
    && autoreconf -if \
    && ./configure \
     --disable-static \
     --disable-fastparser \
     --disable-documentation \
     --disable-daemon \
     --disable-utilities \
     --with-lmdb=no \
    && make "-j$(nproc)" install \
    && ldconfig / || true 
# Copy libknot, libdnssec, libzscanner to runtime
RUN mkdir -p /tmp/root/usr/local/include /tmp/root/usr/local/lib /tmp/root/usr/local/lib/pkgconfig \
    && cp -r /usr/local/include/libknot /usr/local/include/libdnssec /usr/local/include/libzscanner /tmp/root/usr/local/include \
    && cp -r /usr/local/lib/libknot* /usr/local/lib/libdnssec* /usr/local/lib/libzscanner* /tmp/root/usr/local/lib \
    && cp -r /usr/local/lib/pkgconfig/libknot.pc /usr/local/lib/pkgconfig/libdnssec.pc /usr/local/lib/pkgconfig/libzscanner.pc /tmp/root/usr/local/lib/pkgconfig


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ARG KNOT_DNS_RUNTIME_DEPS="gnutls "
ARG KNOT_RESOLVER_RUNTIME_DEPS="lmdb luajit libuv lua5.1-sec lua5.1-socket lua5.1-filesystem lua-compat53 \
                               ca-certificates musl-utils tzdata libstdc++ jansson nettle protobuf-c libedit "
ARG KNOT_RESOLVER_RUNTIME_DEPS_HTTP="lua5.1-http lua5.1-maxminddb "
ARG KNOT_RESOLVER_RUNTIME_DEPS_EXTRA="fstrm@test lua5.1-cqueues "
ARG RUNTIME_DEPS="${KNOT_DNS_RUNTIME_DEPS} ${KNOT_RESOLVER_RUNTIME_DEPS} ${KNOT_RESOLVER_RUNTIME_DEPS_HTTP} \
		${KNOT_RESOLVER_RUNTIME_DEPS_EXTRA} "
RUN echo "@test http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
     && apk add --update --no-cache ${RUNTIME_DEPS} \
     && rm -rf /var/cache/apk/* /usr/local/share/man/* 

# Intermediate container for Knot Resolver build
FROM knot-dns-build AS build

# Build Knot Resolver
ENV RESOLV_VERSION v3.2.1
#ARG CFLAGS="-O2 -fstack-protector -pthread -heap-arrays -pipe -fPIC -FORTIFY_SOURCE=2 -fPIE -fomit-frame-pointer "
ARG CFLAGS="-O4 -pthread -pipe -fPIC -fPIC -FORTIFY_SOURCE=2 -fPIE "
ARG LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now "
ARG CC=clang
ARG CXX=clang++

RUN mkdir -p /tmp/root/etc/knot-resolver
RUN git clone -b ${RESOLV_VERSION} --depth=1 --recursive https://github.com/CZ-NIC/knot-resolver.git /tmp/knot-resolver
RUN cd /tmp/knot-resolver \
    && make -j"$(nproc)" install DESTDIR=/tmp/root \
    && cp ./etc/config.docker /tmp/root/etc/knot-resolver/kresd.conf \
    && cp ./distro/common/root.keys /tmp/root/etc/knot-resolver/


# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      description="Knot DNS team's things are modified and used." \
      url="https://www.knot-resolver.cz"

# Environment
ENV TZ Asia/Tokyo 

# Export DNS over UDP & TCP, DNS-over-TLS
EXPOSE 53/UDP 53/TCP 853/TCP

CMD ["/usr/local/sbin/kresd", "-f", "1", "-c", "/etc/knot-resolver/kresd.conf"]

# Fetch Knot Resolver + Knot DNS libraries from build image
COPY --from=build /tmp/root/ /
RUN ldconfig / || true
