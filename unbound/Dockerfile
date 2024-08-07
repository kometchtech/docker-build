# Build stage
FROM --platform=$TARGETPLATFORM debian:stable AS build

# Environment variables
ARG VERSION="1.9.2" \
    BUILD_BASE="build-essential mold make gawk autoconf automake libtool" \
    BUILD_PKGS="libexpat1-dev libssl-dev libevent-dev libfl-dev libhiredis-dev libsodium-dev libnghttp2-dev curl" \
    CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer -fuse-ld=mold" \
    CXXFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer -fuse-ld=mold" \
    LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now"

# Install build dependencies
RUN apt-get update && apt-get install -y  \
    ${BUILD_BASE} ${BUILD_PKGS} \
    && rm -rf /var/lib/apt/lists/*

# Download and extract Unbound source
WORKDIR /usr/src
RUN curl -fsSL "https://www.nlnetlabs.nl/downloads/unbound/unbound-${VERSION}.tar.gz" | tar xz --strip-components=1

# Configure and build Unbound
RUN ./configure \
    --prefix=/usr/local \
    --with-libevent \
    --with-ssl \
    --sysconfdir=/etc/unbound \
    --with-conf-file=/etc/unbound/unbound.conf \
    --with-pidfile=/var/run/unbound.pid \
    --enable-subnet \
    --enable-sha2 \
    --disable-gost \
    --disable-ecdsa \
    --enable-pie \
    --enable-relro-now \
    --enable-tfo-server \
    --enable-tfo-client \
    --enable-cachedb \
    --with-libhiredis \
    --enable-dnscrypt \
    --with-libnghttp2 \
    --without-pthreads \
    --without-solaris-threads \
    && make -j"$(nproc)" \
    && make strip \
    && make install DESTDIR=/tmp/root

# Runtime stage
FROM --platform=$TARGETPLATFORM debian:stable-slim

# Runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssl libevent-2.1-7 ca-certificates ldnsutils tzdata expat flex bison \
    libhiredis0.14 libsodium23 libnghttp2-14 libexpat1 libprotobuf-c1 bsdmainutils \
    && rm -rf /var/lib/apt/lists/*

# Create unbound user and group
RUN groupadd -r unbound && useradd -r -g unbound -s /sbin/nologin -d /etc/unbound unbound

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
      arch="$TARGETPLATFORM" \
      description="Unbound is a validating, recursive, caching DNS resolver." \
      url="https://nlnetlabs.nl/projects/unbound/about/"

# Run as non-root user
#USER unbound
