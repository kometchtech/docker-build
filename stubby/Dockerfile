# syntax = docker/dockerfile:experimental

# Base stage with common build dependencies
FROM debian:stable AS base-build
# Install base build dependencies
ARG BUILD_BASE="build-essential pkg-config autoconf automake libtool xz-utils curl gettext git libyaml-dev ca-certificates"
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install ${BUILD_BASE} \
    && mkdir -p /usr/src /tmp/root

# Build GnuTLS from source
FROM base-build AS gnutls-build
ARG MAJOR_VERSION="3.8"
ARG GNUTLS_VERSION="${MAJOR_VERSION}.9"
ARG BUILD_PKGS="libssl-dev libgmp-dev libgmpxx4ldbl libtasn1-dev libp11-kit-dev libidn2-dev \
    zlib1g-dev libunbound-dev libunbound8 libunistring-dev libc6 libnettle8 nettle-dev bison python3-minimal"
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer"
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now"

# Install additional dependencies for GnuTLS
RUN DEBIAN_FRONTEND=noninteractive apt-get -y -qqq install ${BUILD_PKGS}

# Download and build GnuTLS
RUN curl -fSsL http://www.ring.gr.jp/pub/net/gnupg/gnutls/v${MAJOR_VERSION}/gnutls-${GNUTLS_VERSION}.tar.xz \
    -o gnutls.tar.xz \
    && tar xf gnutls.tar.xz --strip-components=1 -C /usr/src \
    && rm -f gnutls.tar.xz \
    && cd /usr/src \
    && ./configure \
       --disable-doc \
       --disable-tests \
       --enable-shared \
       --enable-openssl-compatibility \
       --with-default-trust-store-pkcs11="pkcs11:" \
    && make -j"$(nproc)" \
    && make check install \
    && make install DESTDIR=/tmp/root

# Build getdns from source
FROM base-build AS getdns-build
ARG GETDNS_VERSION="1.7.3"
ARG BUILD_PKGS="cmake libunbound-dev libidn2.0-dev libtasn1-dev nettle-dev libssl-dev libev-dev libuv1-dev libevent-dev check"
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer"
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now"

# Copy GnuTLS from previous stage and install additional dependencies
COPY --from=gnutls-build /tmp/root/usr/local/ /usr/local/
RUN DEBIAN_FRONTEND=noninteractive apt-get -y -qqq install ${BUILD_PKGS} \
    && mkdir -p \
       /tmp/root/var/stubby/ \
       /tmp/root/etc/stubby/ \
       /tmp/root/usr/local/lib/ \
       /tmp/root/usr/local/include

# Clone getdns and build with CMake
RUN git clone -b v${GETDNS_VERSION} --depth 1 https://github.com/getdnsapi/getdns.git /usr/src \
    && cd /usr/src \
    && git submodule update --init \
    && mkdir build \
    && cd build \
    && cmake \
       -DENABLE_SYSTEMD=OFF \
       -DENABLE_STATIC=OFF \
       -DBUILD_STUBBY=ON \
       -DSTUB_NATIVE_DNSSEC=ON \
       -DEDNS_COOKIES=ON \
       -DBUILD_LIBEV=ON \
       -DBUILD_LIBEVENT2=ON \
       -DBUILD_LIBUV=ON \
       -DUSE_LIBIDN2=ON \
       -DUSE_GNUTLS=ON \
       .. \
    && make -j"$(nproc)" \
    && make install

# Copy required libraries and files
RUN ldconfig / \
    && cp -r /usr/local/lib/* /tmp/root/usr/local/lib/ \
    && cp -r /usr/local/include/* /tmp/root/usr/local/include/ \
    && rm -rf /tmp/root/var/run /tmp/root/usr/local/share/man/*

# Runtime dependencies stage
FROM debian:stable-slim AS runtime
# Install runtime dependencies
COPY --from=gnutls-build /tmp/root/usr/local/lib /usr/local/lib
ENV RUN_PKGS="libyaml-0-2 libuv1 libev4 libevent-2.1 libunbound8 tini libidn2-0 libtasn1-6 libnettle8 libssl3 ca-certificates"
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install ${RUN_PKGS} \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /usr/local/share/man/* /var/lib/apt/lists/* \
    && mkdir -p /var/cache/stubby \
    && ldconfig /

# Build Stubby
FROM getdns-build AS stubby-build
ARG VERSION="0.4.3"
ARG BUILD_PKGS="libyaml-dev unbound git libyaml-0-2 ca-certificates"
ENV CC=gcc \
    CXX=g++

# Install additional dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get -y -qqq install ${BUILD_PKGS} \
    && mkdir -p \
       /tmp/root/etc/unbound \
       /tmp/root/root/.getdns \
       /tmp/root/usr/local/bin

# Build Stubby
RUN rm -rf /usr/src/stubby \
    && git clone -b v${VERSION} --depth 1 https://github.com/getdnsapi/stubby.git /usr/src/stubby \
    && cd /usr/src/stubby \
    && cmake \
       -DENABLE_SYSTEMD=OFF \
       . \
    && make -j"$(nproc)" \
    && make install DESTDIR=/tmp/root

# Configure Stubby
RUN unbound-anchor -v -a "/tmp/root/etc/unbound/getdns-root.key" || true \
    && cp /usr/src/stubby/stubby.yml.example /tmp/root/etc/stubby/stubby.yml \
    && rm -rf /tmp/root/usr/local/share /tmp/root/usr/local/include \
    && curl -fSsL https://data.iana.org/root-anchors/root-anchors.xml \
         -o /tmp/root/root/.getdns/root-anchors.xml

# Final image
FROM runtime
# Copy the entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy built files from stubby-build stage
COPY --from=stubby-build /tmp/root/ /
RUN ldconfig /

# Environment
ENV TZ Asia/Tokyo

# Publish DNS ports
EXPOSE 53/UDP 53/TCP

# Service control
STOPSIGNAL SIGTERM

# Working directory and entrypoint configuration with tini
WORKDIR /etc/stubby
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["/usr/local/bin/stubby", "-l"]

# Add LABEL at the end to reduce layer impact in multi-stage builds
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="x86_64,arm64" \
      url="https://dnsprivacy.org/wiki/display/DP/DNS+Privacy+Daemon+-+Stubby" \
      description="Stubby is the name given to a mode of using getdns which enables \
                   it to act as a local DNS Privacy stub resolver (using DNS-over-TLS)."
