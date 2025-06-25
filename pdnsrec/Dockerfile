# ===== Build Stage =====
FROM rust:slim AS build

# Define arguments
ARG VERSION="4.2.0"
ARG BUILD_PKGS="build-essential autoconf automake libtool curl libboost-all-dev liblua5.3-dev luajit libluajit-5.1-dev libedit-dev libsodium-dev libprotobuf-dev libgnutls28-dev libatomic-ops-dev libsnmp-dev libfstrm-dev libcurl4-openssl-dev pkg-config"

# Set optimization flags
ARG CFLAGS="-Os -fomit-frame-pointer"
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,--as-needed -rdynamic"

# Install development packages and build dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    apt-get install -y --no-install-recommends ${BUILD_PKGS}

# Create build directory
WORKDIR /usr/src

# Download and extract source code
RUN curl -fsSL "https://downloads.powerdns.com/releases/pdns-recursor-${VERSION}.tar.xz" -o pdns-recursor.tar.xz && \
    tar xf pdns-recursor.tar.xz --strip-components=1 && \
    rm -f pdns-recursor.tar.xz

# Configure build
RUN ./configure \
      --prefix=/usr/local \
      --sysconfdir=/etc/powerdns \
      --localstatedir=/var \
      --libdir=/usr/local/lib \
      --libexecdir=/usr/local/lib \
      --disable-static \
      --with-net-snmp \
      --with-service-group=pdns-recursor \
      --with-service-user=pdns-recursor \
      --with-lua \
      --enable-dns-over-tls \
      CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}"

# Compile and install
RUN make -j$(( $(nproc) > 6 ? 6 : $(nproc) )) install DESTDIR=/tmp/root && \
    strip /tmp/root/usr/local/bin/* /tmp/root/usr/local/sbin/* 2>/dev/null || true && \
    rm -rf /tmp/root/usr/local/share/man/* \
           /tmp/root/usr/local/share/doc/*

# ===== Runtime Stage =====
FROM debian:stable-slim

# Install runtime dependencies
ARG RUN_PKGS="libboost-context1.74.0 libboost-filesystem1.74.0 libboost-system1.74.0 libboost-thread1.74.0 \
              liblua5.3-0 libluajit-5.1-2 libedit2 libprotobuf32 libsodium23 tzdata libgnutls30 \
              libatomic1 ca-certificates tini libsnmp40 libfstrm0 libcurl4"

RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    apt-get -y install --no-install-recommends ${RUN_PKGS} && \
    groupadd -r pdns-rec && \
    useradd -r -g pdns-rec -s /bin/false -d /etc pdns-recursor && \
    rm -rf /var/lib/apt/lists/* /usr/local/share/man/* /var/tmp/* && \
    mkdir -p /var/lib/pdns-recursor/nod /var/lib/pdns-recursor/udr /var/run/pdns-recursor

# Environment configuration
ENV TZ=Asia/Tokyo

# Copy built binaries
COPY --from=build /tmp/root/ /
RUN ldconfig

# Add entrypoint script
COPY ./entrypoint.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/entrypoint.sh

# Expose ports
# Web server port
EXPOSE 8082
# DNS ports 
EXPOSE 53/udp 53/tcp

# Stop signal
STOPSIGNAL SIGTERM

# Execution configuration
WORKDIR /etc/powerdns
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/sbin/entrypoint.sh"]
CMD ["pdns_recursor", "--disable-syslog", "--log-timestamp=yes", "--config-dir=/etc/powerdns"]

# Metadata configuration (placed at the end for build cache optimization)
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      description="The PowerDNS Recursor is a high-end, high-performance resolving name server which powers the DNS resolution of at least a hundred million subscribers." \
      url="https://www.powerdns.com/recursor.html"
