# Intermediate container for Knot DNS build (not persistent)
FROM arm64v8/alpine:latest AS knot-dns-build
ARG KNOT_DNS_VERSION=v2.7.4

# Build dependencies
ENV KNOT_DNS_BUILD_DEPS build-base automake autoconf libtool pkgconfig userspace-rcu-dev \
			gnutls curl gawk git bsd-compat-headers \
			musl-utils fstrm-dev@test protobuf-c-dev protobuf-dev
ENV KNOT_RESOLVER_BUILD_DEPS build-base automake autoconf libtool pkgconfig git luajit-dev libuv-dev \
			gnutls-dev fstrm-dev@test jansson-dev userspace-rcu-dev curl vim bsd-compat-headers nettle-dev \
			binutils cmocka-dev protobuf-c-dev protobuf-dev lua5.3-sec lua5.3-socket lua5.3-filesystem
ENV BUILDENV_DEPS ${KNOT_DNS_BUILD_DEPS} ${KNOT_RESOLVER_BUILD_DEPS}
ARG CFLAGS="-O2 -fstack-protector -pthread -heap-arrays -pipe -fPIC -FORTIFY_SOURCE=2 -fPIE -fomit-frame-pointer "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now "

# Install dependencies and sources
RUN echo "@test http://dl-cdn.alpinelinux.org/alpine/edge/testing" | tee -a /etc/apk/repositories \
  && apk add --no-cache --update ${BUILDENV_DEPS} \
# Install Knot DNS from sources
  && git clone -b ${KNOT_DNS_VERSION} --depth=1 https://gitlab.labs.nic.cz/knot/knot-dns.git /tmp/knot-dns \
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
    && ldconfig / || true \
# Copy libknot, libdnssec, libzscanner to runtime
    && mkdir -p /tmp/root/usr/local/include /tmp/root/usr/local/lib /tmp/root/usr/local/lib/pkgconfig \
    && cp -r /usr/local/include/libknot /usr/local/include/libdnssec /usr/local/include/libzscanner /tmp/root/usr/local/include \
    && cp -r /usr/local/lib/libknot* /usr/local/lib/libdnssec* /usr/local/lib/libzscanner* /tmp/root/usr/local/lib \
    && cp -r /usr/local/lib/pkgconfig/libknot.pc /usr/local/lib/pkgconfig/libdnssec.pc /usr/local/lib/pkgconfig/libzscanner.pc /tmp/root/usr/local/lib/pkgconfig

# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ENV KNOT_DNS_RUNTIME_DEPS gnutls  
ENV KNOT_RESOLVER_RUNTIME_DEPS lmdb luajit libuv lua5.3-sec lua5.3-socket lua5.3-filesystem \
                               ca-certificates musl-utils tzdata libstdc++ jansson nettle protobuf-c
ENV KNOT_RESOLVER_RUNTIME_DEPS_HTTP lua5.3-http lua5.3-maxminddb 
ENV KNOT_RESOLVER_RUNTIME_DEPS_EXTRA fstrm@test lua5.3-cqueues
ENV RUNTIME_DEPS ${KNOT_DNS_RUNTIME_DEPS} ${KNOT_RESOLVER_RUNTIME_DEPS} ${KNOT_RESOLVER_RUNTIME_DEPS_HTTP} \
		${KNOT_RESOLVER_RUNTIME_DEPS_EXTRA}
RUN echo "@test http://dl-cdn.alpinelinux.org/alpine/edge/testing" | tee -a /etc/apk/repositories \
     && apk add --no-cache --update  ${RUNTIME_DEPS} \
     && rm -rf /var/cache/apk/* /usr/local/share/man/* 

# Intermediate container for Knot Resolver build
FROM knot-dns-build AS build

# Build Knot Resolver
ARG KNOT_RESOLVER_VER=v3.2.0
ARG CFLAGS="-O2 -fstack-protector -pthread -heap-arrays -pipe -fomit-frame-pointer -fPIC -FORTIFY_SOURCE=2 -fPIE "
ARG LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now "
RUN git clone -b ${KNOT_RESOLVER_VER} --recursive https://github.com/CZ-NIC/knot-resolver.git /tmp/knot-resolver && \
        cd /tmp/knot-resolver && \
        make -j"$(nproc)" && \
        make install DESTDIR=/tmp/root && \
        mkdir -p /tmp/root/etc/knot-resolver && \
        cp ./etc/config.docker /tmp/root/etc/knot-resolver/kresd.conf && \
        cp ./distro/common/root.keys /tmp/root/etc/knot-resolver/


# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      description="Knot DNS team's things are modified and used." \
      url="https://www.knot-dns.cz/"

ENV TZ Asia/Tokyo 

# Export DNS over UDP & TCP, DNS-over-TLS, web interface
EXPOSE 53/UDP 53/TCP 853/TCP 8053/TCP

CMD ["/usr/local/sbin/kresd", "-c", "/etc/knot-resolver/kresd.conf"]

# Fetch Knot Resolver + Knot DNS libraries from build image
COPY --from=build /tmp/root/ /
RUN ldconfig / || true
