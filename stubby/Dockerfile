# syntax = docker/dockerfile:experimental

# Base stage with common build dependencies
FROM debian:stable AS base-build

# Install base build dependencies
ARG BUILD_BASE="cmake build-essential pkg-config autoconf automake libtool xz-utils curl gettext git libyaml-dev ca-certificates libssl-dev"
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install ${BUILD_BASE} \
    && mkdir -p /usr/src /tmp/root

# Build getdns from source
FROM base-build AS getdns-build

ARG GETDNS_VERSION="1.7.3"
ARG BUILD_PKGS="libidn2-dev check libev-dev libuv1-dev libevent-dev "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer"
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now"

# Create required directories first
RUN mkdir -p \
       /tmp/root/var/stubby/ \
       /tmp/root/etc/stubby/ \
       /tmp/root/usr/local/lib/ \
       /tmp/root/usr/local/include

RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install --no-install-recommends ${BUILD_PKGS} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && ldconfig 

# Clone getdns and build with CMake
RUN git clone -b v${GETDNS_VERSION} --depth 1 https://github.com/getdnsapi/getdns.git /usr/src \
    && cd /usr/src \
    && git submodule update --init \
    && mkdir build \
    && cd build \
    && cmake \
       -DENABLE_SYSTEMD=OFF \
       -DENABLE_STUB_ONLY=ON \
       -DUSE_LIBIDN2=OFF \
       .. \
    && make -j"$(nproc)" \
    && make install

# Copy required libraries and files
RUN ldconfig / \
    && cp -r /usr/local/lib/* /tmp/root/usr/local/lib/ \
    && cp -r /usr/local/include/* /tmp/root/usr/local/include/

# Build Stubby
FROM getdns-build AS stubby-build

ARG VERSION
ARG BUILD_PKGS="libyaml-dev unbound-anchor "
ENV CC=gcc \
    CXX=g++

# Install additional dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install ${BUILD_PKGS} \
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


# Runtime base image
FROM debian:stable-slim AS runtime-base

# Install tini and runtime dependencies
ARG RUN_PKGS="libyaml-0-2 libuv1 libev4 libevent-2.1 tini libidn2-0 ca-certificates libp11-kit0 libssl3"
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install --no-install-recommends ${RUN_PKGS} \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/cache/stubby \
    && chmod 777 /var/cache/stubby

# Final runtime image
FROM runtime-base AS final
ARG VERSION

# Copy built Stubby and configuration
COPY --from=stubby-build /tmp/root/ /

# Copy the entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Update library cache
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
      url="https://dnsprivacy.org/wiki/display/DP/DNS+Privacy+Daemon+-+Stubby" \
      description="Stubby is the name given to a mode of using getdns which enables \
                   it to act as a local DNS Privacy stub resolver (using DNS-over-TLS)."
