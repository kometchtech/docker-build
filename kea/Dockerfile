# syntax = docker/dockerfile:1.4
# Multi-architecture build for x86_64 and arm64

##############################################################################
# Base image for all stages
##############################################################################
FROM debian:stable-slim AS base

ARG VERSION=2.7.6

# Common environment variables
ENV TZ=Asia/Tokyo \
    DEBIAN_FRONTEND=noninteractive

# Common build flags
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer -Wno-enum-constexpr-conversion"
ARG CXXFLAGS="${CFLAGS} -std=c++20"
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now -fuse-ld=lld"
ARG CC="clang"
ARG CXX="clang++"

# Install base packages
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        build-essential \
        binutils \
        autoconf \
        automake \
        libtool \
        curl \
        ca-certificates \
        pkg-config \
        xz-utils \
        clang-19 \
        lld-19 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-19 100 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-19 100 && \
    update-alternatives --install /usr/bin/lld lld /usr/bin/lld-19 100

##############################################################################
# Build log4cplus library
##############################################################################
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
    curl -fSsL "https://github.com/log4cplus/log4cplus/releases/download/REL_${LOG4CPLUS_TAG}/log4cplus-${LOG4CPLUS}.tar.xz" -o log4cplus.tar.xz && \
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

##############################################################################
# Build botan library
##############################################################################
FROM base AS botan-builder

# Environment variables
ENV BOTAN="3.7.1"

# Install botan dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        libboost-dev \
        libboost-system-dev \
        zlib1g-dev \
        python3 \
        python3-setuptools \
        libsqlite3-dev \
        libbz2-dev \
        libboost-filesystem-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download and extract botan
RUN mkdir -p /usr/local/src && \
    curl -fsSL "https://botan.randombit.net/releases/Botan-${BOTAN}.tar.xz" -o botan.tar.xz && \
    tar xf botan.tar.xz --strip-components=1 -C /usr/local/src && \
    rm botan.tar.xz

# Build botan
WORKDIR /usr/local/src
RUN ./configure.py \
        --optimize-for-size \
        --with-boost \
        --with-zlib \
        --with-commoncrypto \
        --with-sqlite3 \
        --with-bzip2 \
        --disable-static-library \
        --without-documentation \
        --cc-bin=clang++ \
        --cxxflags="-std=c++20" && \
    make -j$(nproc) install DESTDIR=/opt/botan && \
    rm -f /opt/botan/usr/local/bin/botan

##############################################################################
# Build Kea
##############################################################################
FROM base AS kea-builder

# Copy built dependencies
COPY --from=log4cplus-builder /opt/log4cplus/ /
COPY --from=botan-builder /opt/botan/ /

# Install kea build dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        libboost-dev \
        libboost-system-dev \
        postgresql-server-dev-all \
        default-libmysqlclient-dev \
        bison \
        flex \
        perl \
        libssl-dev \
        g++ && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    ldconfig

# Download and extract Kea source
ARG VERSION
RUN mkdir -p /usr/src/kea && \
    curl -fSsL "https://ftp.isc.org/isc/kea/${VERSION}/kea-${VERSION}.tar.gz" -o kea.tar.gz && \
    tar xf kea.tar.gz --strip-components=1 -C /usr/src/kea && \
    rm -f kea.tar.gz

# Build Kea
WORKDIR /usr/src/kea
RUN autoreconf -if && \
    export CC="gcc" && \
    export CXX="g++" && \
    export CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer" && \
    export CXXFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer -std=c++17" && \
    export LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now" && \
    ./configure \
        --prefix=/usr/local \
        --sysconfdir=/etc \
        --disable-rpath \
        --disable-static \
        --with-boost-include \
        --with-botan-config \
        --with-openssl \
        --with-mysql \
        --with-pgsql \
        --with-log4cplus && \
    make -j$(nproc) && \
    make install DESTDIR=/opt/kea

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

##############################################################################
# Final image
##############################################################################
FROM debian:stable-slim

# Install runtime dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        libboost-system1.74.0 \
        libpq5 \
        tzdata \
        procps \
        libatomic1 \
        libsqlite3-0 \
        libbz2-1.0 \
        libmariadb3 \
        tini \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/local/share/man/* && \
    mkdir -p /var/lib/kea /usr/local/var/run/kea

# Copy built binaries and libraries
COPY --from=log4cplus-builder /opt/log4cplus/ /
COPY --from=botan-builder /opt/botan/ /
COPY --from=kea-builder /opt/kea/ /

# Add entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh && ldconfig

# Environment
ENV TZ=Asia/Tokyo

# Expose ports
EXPOSE 67/UDP 547/TCP 547/UDP 8080

# Configure service
STOPSIGNAL SIGTERM
WORKDIR /etc/kea
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["/usr/local/bin/entrypoint.sh"]

# Labels (placed at the end to minimize build cache impact)
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      description="Kea is an open source implementation of the Dynamic Host Configuration Protocol (DHCP) servers, developed and maintained by Internet Systems Consortium (ISC)." \
      url="https://www.isc.org/kea/"
