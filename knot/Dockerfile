# syntax = docker/dockerfile:experimental
# -----------------------------------------------------
# Build stage: compile Knot DNS from source
# -----------------------------------------------------
FROM debian:stable AS build

# Environment
ARG VERSION="3.4.5"
ARG CFLAGS="-Os -fomit-frame-pointer"
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,--as-needed -rdynamic"

# Build dependencies
ARG BUILD_BASE="build-essential autoconf automake wget libtool"
ARG KNOT_DNS_BUILD_DEPS="${BUILD_BASE} pkg-config liblmdb-dev libmaxminddb-dev liburcu-dev libfstrm-dev \
                         libprotobuf-c-dev libprotobuf-dev libedit-dev zlib1g-dev libidn2-0-dev protobuf-c-compiler libxdp-dev \
                         libmnl-dev libnghttp2-dev libngtcp2-crypto-gnutls-dev libngtcp2-dev libgnutls28-dev libbpf-dev"

# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qq install ${KNOT_DNS_BUILD_DEPS}

# Download and extract Knot DNS source
RUN mkdir -p /tmp/root/etc/knot-dns \
    && wget -nv https://secure.nic.cz/files/knot-dns/knot-${VERSION}.tar.xz -O /tmp/knot-${VERSION}.tar.xz \
    && tar Jxf /tmp/knot-${VERSION}.tar.xz -C /tmp

# Build Knot DNS
RUN cd /tmp/knot-${VERSION} \
    && autoreconf -if \
    && ./configure \
      --prefix=/usr/local \
      --with-configdir=/etc/knot \
      --with-rundir=/run/knot \
      --disable-fastparser \
      --disable-documentation \
      --enable-reuseport=auto \
      --enable-recvmmsg=auto \
      --enable-systemd=no \
      --enable-quic \
      --enable-dnstap \
      --disable-static \
      CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
    && make -j $(nproc) \
    && make install DESTDIR=/tmp/root

# Copy and process sample configuration
RUN mkdir -p /tmp/root/etc/knot-dns \
    && cp /tmp/knot-${VERSION}/samples/knot.sample.conf.in /tmp/root/etc/knot-dns/knot.sample.conf \
    && sed -i 's|@storage_dir@|/var/lib/knot|g' /tmp/root/etc/knot-dns/knot.sample.conf \
    && sed -i 's|@run_dir@|/run/knot|g' /tmp/root/etc/knot-dns/knot.sample.conf \
    && sed -i 's|@conf_dir@|/etc/knot|g' /tmp/root/etc/knot-dns/knot.sample.conf

# -----------------------------------------------------
# Runtime dependencies stage: prepare runtime environment
# -----------------------------------------------------
FROM debian:stable-slim AS runtime

# Install runtime dependencies
ARG KNOT_DNS_RUNTIME_DEPS="libbpf1 libedit2 libfstrm0 libgnutls30 libidn2-0 liblmdb0 libmaxminddb0 tini \
                           libmnl0 libnghttp2-14 libngtcp2-crypto-gnutls8 libngtcp2-16 libprotobuf-c1 liburcu8 libxdp1"

RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qq install --no-install-recommends ${KNOT_DNS_RUNTIME_DEPS} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /usr/local/share/man/*

# -----------------------------------------------------
# Final stage: combine runtime and compiled binaries
# -----------------------------------------------------
FROM runtime

# Pass VERSION from build stage to final image
ARG VERSION

# Copy binaries and libraries from build stage
COPY --from=build /tmp/root/ /

# Setup environment
ENV TZ Asia/Tokyo

# Create necessary directories
RUN mkdir -p /run/knot /var/lib/knot \
    && ldconfig /

# Configure entrypoint
COPY entrypoint.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/entrypoint.sh

# Expose ports: DNS over UDP & TCP, DNS-over-TLS
EXPOSE 53/UDP 53/TCP 853/TCP

# Set default working directory
WORKDIR /etc/knot-dns

# Handle service termination gracefully
STOPSIGNAL SIGTERM

# Define entrypoint
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/sbin/entrypoint.sh"]

# Add metadata labels (at the end to minimize layer invalidation)
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      description="Knot DNS authoritative server" \
      url="https://www.knot-dns.cz/" \
      version="${VERSION}"
