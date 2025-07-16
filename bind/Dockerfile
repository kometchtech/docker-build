# syntax = docker/dockerfile:1.4

# Common build dependencies stage
FROM debian:stable AS common-build

# Common environment variables for build configuration
ARG COMMON_BUILD_PKGS="build-essential curl ca-certificates git python3 meson pkg-config ninja-build"

# Install common build dependencies for better caching
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get install -y --no-install-recommends ${COMMON_BUILD_PKGS} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Build dependencies stage
FROM common-build AS build-deps

# Additional build dependencies for BIND
ARG BUILD_PKGS="gawk ldnsutils \
                libssl-dev libcap-dev libperl-dev libedit-dev libreadline-dev libncurses-dev libjemalloc-dev libidn2-dev libfstrm-dev \
                libxml2-dev libjson-c-dev libbsd-dev libuv1-dev libstdc++-11-pic libc6 libnghttp2-dev liburcu-dev \
                libmaxminddb-dev liblmdb-dev libkrb5-dev libgssapi-krb5-2 zlib1g-dev libcmocka-dev "

# Install build dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get install -y --no-install-recommends ${BUILD_PKGS} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Build BIND in a separate stage
FROM build-deps AS build

# Import version from build args
ARG VERSION
ARG CFLAGS="-Os -fomit-frame-pointer"
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,--as-needed"

# Download and extract source
WORKDIR /tmp/build
RUN mkdir -p /tmp/download \
    && curl -fsSL "https://downloads.isc.org/isc/bind9/${VERSION}/bind-${VERSION}.tar.xz" -o /tmp/download/bind-${VERSION}.tar.xz \
    && tar xf /tmp/download/bind-${VERSION}.tar.xz --strip-components=1 -C /tmp/build \
    && rm -f /tmp/download/bind-${VERSION}.tar.xz

# Configure with Meson build system
RUN meson setup build \
    --prefix=/usr/local \
    --sysconfdir=/etc/named \
    --localstatedir=/var \
    --buildtype=release \
    --strip \
    --optimization=s \
    -Dgssapi=enabled \
    -Dlmdb=enabled \
    -Dzlib=enabled

# Build with parallel compilation for speed
RUN meson compile -C build -j$(nproc)

# Install to temporary directory, exclude docs and tests
RUN DESTDIR=/tmp/root meson install -C build \
    && ldconfig / \
    && mkdir -p /tmp/root/var/cache/named \
    && rm -rf /tmp/root/var/run \
           /tmp/root/usr/local/share/man \
           /tmp/root/usr/local/share/doc \
           /tmp/root/usr/local/include \
           /tmp/root/usr/local/lib/pkgconfig \
           /tmp/root/usr/local/share/info \
           /tmp/root/usr/local/lib/*.la

# Download root hints
RUN curl -fsSL "https://www.internic.net/domain/named.root" -o /tmp/root/var/cache/named/named.ca


# Runtime dependencies stage
FROM debian:stable-slim AS runtime

# Install runtime dependencies
ARG RUN_PKGS="libprotobuf-c1 tzdata openssl libcap2 libjson-c5 libxml2 libuv1 libnghttp2-14 liburcu8 tini libjemalloc2 libidn2-0 \
              libfstrm0 liblmdb0 libmaxminddb0 libkrb5-3 libgssapi-krb5-2 zlib1g"

RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install --no-install-recommends ${RUN_PKGS} \
    && apt-get clean \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /usr/local/share/man/* /var/lib/apt/lists/* /usr/share/doc/* /usr/share/man/* \
    # Add non-root user for BIND
    && groupadd -r _named \
    && useradd -r -g _named -s /dev/null -d /etc _named \
    && mkdir -p /etc/named /var/cache/named /var/run/named /var/cache/named/dynamic /var/cache/named/pri

# Final container
FROM runtime

# Copy BIND binaries and configurations from build stage
COPY --from=build /tmp/root/ /
COPY ./named.conf /etc/named/named.conf
COPY ./local.rev ./local.zone /var/cache/named/pri/

# Environment
ENV TZ=Asia/Tokyo

# Set proper permissions
RUN chown -R _named:_named /var/cache/named /etc/named /var/run/named /var/cache/named/dynamic \
    && chmod 0750 /etc/named /var/cache/named /var/run/named \
    && ldconfig /

# Copy and setup entrypoint script
COPY ./entrypoint.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/entrypoint.sh

# Expose DNS ports (TCP & UDP) and control port
EXPOSE 53/tcp 53/udp 953/tcp

# Service management
STOPSIGNAL SIGTERM

# Working directory and execution
WORKDIR /etc/named
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/sbin/entrypoint.sh"]
CMD ["/usr/local/sbin/named", "-c", "/etc/named/named.conf", "-g", "-u", "_named"]

# Metadata (placed last to reduce impact on layer caching)
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      org.opencontainers.image.title="BIND DNS Server" \
      org.opencontainers.image.description="BIND is open source software that enables you to publish your \
                  Domain Name System (DNS) information on the Internet, and to \
                  resolve DNS queries for your users. The name BIND stands for \
                  Berkeley Internet Name Domain, because the software originated \
                  in the early 1980s at the University of California at Berkeley." \
      org.opencontainers.image.url="https://www.isc.org/downloads/bind/" \
      org.opencontainers.image.source="https://github.com/isc-projects/bind9"
