# Build stage
FROM debian:stable AS build

# Environment variables
ARG VERSION=1.20.0
ARG BUILD_BASE="build-essential make gawk autoconf automake libtool curl ldnsutils"
ARG BUILD_PKGS="libexpat1-dev libssl-dev libevent-dev libfl-dev libhiredis-dev libsodium-dev libnghttp2-dev libprotobuf-c-dev protobuf-c-compiler ca-certificates" 
ARG CFLAGS="-Os -fomit-frame-pointer"
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,--as-needed"

# Install build dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    apt-get install -y --no-install-recommends ${BUILD_BASE} ${BUILD_PKGS} \
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates

# Download and extract Unbound source
WORKDIR /usr/src
RUN curl -fsSL "https://www.nlnetlabs.nl/downloads/unbound/unbound-${VERSION}.tar.gz" | tar zx --strip-components 1 

# Configure and build Unbound
RUN ./configure \
    --prefix=/usr/local \
    --with-libevent \
    --sysconfdir=/etc/unbound \
    --with-conf-file=/etc/unbound/unbound.conf \
    --with-pidfile=/var/run/unbound.pid \
    --enable-subnet \
    --enable-sha2 \
    --disable-gost \
    --disable-ecdsa \
    --enable-tfo-server \
    --enable-tfo-client \
    --enable-cachedb \
    --with-libhiredis \
    --enable-dnscrypt \
    --with-libnghttp2 \
    --with-pthreads \
    --with-deprecate-rsa-1024 \
    && make -j$(nproc) \
    && make strip \
    && make install DESTDIR=/tmp/root

# Runtime stage
FROM debian:stable-slim

# Runtime dependencies
ARG RUNTIME_PKGS="curl openssl libevent-2.1-7 ca-certificates ldnsutils tzdata \
                  expat flex bison libhiredis0.14 libsodium23 libnghttp2-14 \
                  libexpat1 libprotobuf-c1 bsdmainutils"

RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    apt-get install -y --no-install-recommends ${RUNTIME_PKGS} \
    && rm -rf /var/lib/apt/lists/*

# Create unbound user and group
RUN groupadd -r unbound \
    && useradd -r -g unbound -s /sbin/nologin -d /etc/unbound unbound

# Copy Unbound files from build stage
COPY --from=build /tmp/root/ /
RUN ldconfig

# Set environment variables
ENV TZ=Asia/Tokyo

# Create necessary directories with correct permissions
RUN mkdir -p /var/run/unbound /var/lib/unbound \
    && chown -R unbound:unbound /var/run/unbound /var/lib/unbound /etc/unbound

# Copy entrypoint script
COPY entrypoint.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/entrypoint.sh

# Expose ports
EXPOSE 53/tcp 53/udp 853/tcp

# Set working directory
WORKDIR /etc/unbound

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
  CMD unbound-control status || exit 1

# Set entrypoint and default command
ENTRYPOINT ["/usr/local/sbin/entrypoint.sh"]
CMD ["unbound", "-d", "-c", "/etc/unbound/unbound.conf"]

# Labels
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      description="Unbound is a validating, recursive, caching DNS resolver." \
      url="https://nlnetlabs.nl/projects/unbound/about/"

