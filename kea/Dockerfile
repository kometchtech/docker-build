# syntax = docker/dockerfile:1.4

# Base image for all stages
FROM debian:stable AS base

ARG VERSION=2.7.6

# Common environment variables
ENV TZ=Asia/Tokyo

# Common build flags
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer -Wno-enum-constexpr-conversion"
ARG CXXFLAGS="${CFLAGS} -std=c++20"
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now -fuse-ld=lld"
ARG CC="clang"
ARG CXX="clang++"
ARG BUILD_PKGS="build-essential binutils autoconf automake libtool curl ca-certificates pkg-config xz-utils clang-19 lld-19"

# Install base packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get install -y ${BUILD_PKGS} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-19 100 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-19 100 \
    && update-alternatives --install /usr/bin/lld lld /usr/bin/lld-19 100

# Build log4cplus library
FROM base AS log4cplus-builder

# Environment variables
ENV LOG4CPLUS="2.1.2"
# Convert dots to underscores for GitHub tag format
RUN LOG4CPLUS_TAG=$(echo ${LOG4CPLUS} | tr '.' '_') && \
    echo "LOG4CPLUS_SOURCE=https://github.com/log4cplus/log4cplus/releases/download/REL_${LOG4CPLUS_TAG}/log4cplus-${LOG4CPLUS}.tar.bz2" >> /etc/environment && \
    . /etc/environment

# Download and extract log4cplus
RUN mkdir -p /usr/local/src && \
    LOG4CPLUS_TAG=$(echo ${LOG4CPLUS} | tr '.' '_') && \
    curl -fSL "https://github.com/log4cplus/log4cplus/releases/download/REL_${LOG4CPLUS_TAG}/log4cplus-${LOG4CPLUS}.tar.xz" -o log4cplus.tar.xz && \
    tar xf log4cplus.tar.xz --strip-components=1 -C /usr/local/src && \
    rm log4cplus.tar.xz

# Build log4cplus
WORKDIR /usr/local/src
RUN ./configure \
        CFLAGS="${CFLAGS}" \
        CXXFLAGS="${CXXFLAGS}" \
        LDFLAGS="${LDFLAGS}" && \
    make -j$(nproc) && \
    make install-strip DESTDIR=/opt/log4cplus

# Build Kea
FROM base AS kea-builder

# Copy built dependencies
COPY --from=log4cplus-builder /opt/log4cplus /

ARG BUILD_PKGS="libboost-dev libboost-system-dev postgresql-server-dev-all default-libmysqlclient-dev \
                bison flex perl libssl-dev "
# Install kea build dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get install -y --no-install-recommends ${BUILD_PKGS} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && ldconfig

# 環境変数を設定
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH:-}"

# Download and extract Kea source
ARG VERSION
RUN mkdir -p /usr/src/kea && \
    curl -fSL "https://ftp.isc.org/isc/kea/${VERSION}/kea-${VERSION}.tar.xz" -o kea.tar.xz && \
    tar -xf kea.tar.xz --strip-components=1 -C /usr/src/kea && \
    rm -f kea.tar.xz

# Build Kea
WORKDIR /usr/src/kea
RUN autoreconf -if && \
    export CC="clang" && \
    export CXX="clang++" && \
    export CFLAGS="${CFLAGS}" && \
    export CXXFLAGS="${CXXFLAGS}" && \
    export LDFLAGS="${LDFLAGS}" && \
    export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH:-}" && \
    ./configure \
        --prefix=/usr/local \
        --sysconfdir=/etc \
        --disable-rpath \
        --disable-static \
        --with-boost-include \
        --with-openssl \
        --with-mysql \
        --with-pgsql \
        --with-log4cplus && \
    make -j$(nproc) && \
    make install DESTDIR=/opt/kea
RUN find /opt/kea/usr/local/sbin -type f -exec sh -c 'file -b "$1" | grep -q "ELF" && strip "$1" || true' _ {} \;

# Remove unnecessary files
RUN rm -rf /opt/kea/var/run \
           /opt/kea/usr/local/share/man/* \
           /opt/kea/usr/local/include \
           /opt/kea/usr/include \
           /opt/kea/usr/share/kea \
           /opt/kea/usr/share/doc/kea \
           /opt/kea/usr/local/lib/kea/hooks/*.la \
           /opt/kea/usr/local/lib/*.la \
           /opt/kea/usr/local/include/*

# Final image
FROM debian:stable-slim

ARG RUNTIME_PKGS="libboost-system1.74.0 libpq5 tzdata libc6 libatomic1 libsqlite3-0 libbz2-1.0 \
                  libmariadb3 tini ca-certificates"

# Install runtime dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get install -y --no-install-recommends ${RUNTIME_PKGS} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /usr/local/share/man/* \
    && mkdir -p /var/lib/kea /usr/local/var/run/kea

# Copy built binaries and libraries
COPY --from=log4cplus-builder /opt/log4cplus /
# COPY --from=botan-builder /opt/botan /
COPY --from=kea-builder /opt/kea /

# Add entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh && \
    ldconfig

# Environment
ENV TZ=Asia/Tokyo

# Expose ports
EXPOSE 67/UDP 547/TCP 547/UDP 8080/TCP 8000/TCP

# Configure service
STOPSIGNAL SIGTERM
WORKDIR /etc/kea
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["/usr/local/bin/entrypoint.sh"]

# Labels (placed at the end to minimize build cache impact)
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      description="Kea is an open source implementation of the Dynamic Host Configuration Protocol (DHCP) servers, developed and maintained by Internet Systems Consortium (ISC)." \
      url="https://www.isc.org/kea/"
