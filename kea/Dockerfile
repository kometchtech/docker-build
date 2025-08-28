# syntax = docker/dockerfile:1.4

# Base image for all stages
FROM debian:stable AS base

ARG VERSION

# Common build flags
ARG BUILD_PKGS="build-essential binutils ca-certificates curl xz-utils \
                pkg-config ninja-build python3-pip python3-dev python3-setuptools \
                python3-wheel clang lld"

# Install base packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get install -y ${BUILD_PKGS} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-19 100 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-19 100 \
    && update-alternatives --install /usr/bin/lld lld /usr/bin/lld-19 100

# Install modern Meson version via pip (required for Kea 3.0.0)
RUN pip3 install --break-system-packages --no-cache-dir meson>=1.8.0 \
    && ln -sf /usr/local/bin/meson /usr/bin/meson

# Common environment variables and build flags
ENV TZ=Asia/Tokyo \
    CC=clang \
    CXX=clang++ \
    CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer -Wno-enum-constexpr-conversion" \
    CXXFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer -Wno-enum-constexpr-conversion -std=c++20" \
    LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now -fuse-ld=lld"

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
        LDFLAGS="${LDFLAGS}" \
        --disable-static \
        --enable-shared \
        --prefix=/usr/local \
    && make -j$(nproc) \
    && make install-exec DESTDIR=/opt/log4cplus \
    && make install-data DESTDIR=/opt/log4cplus \
    && find /opt/log4cplus -name "*.la" -delete \
    && find /opt/log4cplus -name "*.a" -delete

# Build Kea
FROM base AS kea-builder

ARG KEA_BUILD_PKGS="libboost-dev libboost-system-dev postgresql-server-dev-all \
                default-libmysqlclient-dev bison flex perl libssl-dev python3-dev"
# Install kea build dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get install -y --no-install-recommends ${KEA_BUILD_PKGS} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /usr/share/man/* /usr/share/doc/*

# Copy log4cplus from previous stage
COPY --from=log4cplus-builder /opt/log4cplus /

# Update library paths
RUN ldconfig

# Set up environment for Kea build
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH:-}"

# Download and extract Kea source
ARG VERSION
RUN mkdir -p /usr/src/kea \
    && curl -fSL "https://ftp.isc.org/isc/kea/${VERSION}/kea-${VERSION}.tar.xz" -o kea.tar.xz \
    && tar -xf kea.tar.xz --strip-components=1 -C /usr/src/kea \
    && rm -f kea.tar.xz

WORKDIR /usr/src/kea

# Configure Kea build with Meson
RUN meson setup build \
        --prefix=/usr/local \
        --sysconfdir=/etc \
        --buildtype=release \
        --strip \
        --default-library=shared \
	    -D mysql=enabled \
	    -D postgresql=enabled

# Build Kea
RUN meson compile -C build -j $(nproc) \
    && DESTDIR=/opt/kea meson install -C build

# Strip binaries and remove unnecessary files
RUN find /opt/kea -type f -executable -exec strip --strip-unneeded {} \; 2>/dev/null || true \
    && rm -rf /opt/kea/usr/local/share/man \
           /opt/kea/usr/local/include \
           /opt/kea/usr/local/share/doc \
           /opt/kea/usr/local/lib/pkgconfig \
           /opt/kea/usr/local/lib/*.a

# Final image
FROM debian:stable-slim

ARG RUNTIME_PKGS="libboost-system1.83.0 libpq5 tzdata libc6 libatomic1 libsqlite3-0 \
                  libbz2-1.0 libmariadb3 tini ca-certificates libssl3 "

# Install runtime dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get install -y --no-install-recommends ${RUNTIME_PKGS} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
              /usr/local/share/man/* \
              /usr/share/doc/* \
              /usr/share/info/* \
              /var/cache/debconf/* \
    && mkdir -p /var/lib/kea /usr/local/var/run/kea

# Copy built binaries and libraries
COPY --from=log4cplus-builder /opt/log4cplus /
COPY --from=kea-builder /opt/kea /

# Add entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh && \
    ldconfig

# Environment
ENV TZ=Asia/Tokyo

# Create non-root user for security
RUN groupadd -r kea && useradd -r -g kea -d /var/lib/kea -s /sbin/nologin kea \
    && chown -R kea:kea /var/lib/kea /usr/local/var/run/kea

# Expose standard DHCP and control ports
EXPOSE 67/udp 68/udp 547/tcp 547/udp 8080/tcp 8000/tcp

# Configure container
STOPSIGNAL SIGTERM
WORKDIR /etc/kea

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]

# Metadata labels (placed at the end to minimize layer cache impact)
ARG VERSION
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      description="Kea ${VERSION} - Open source DHCP server implementation by ISC" \
      version="${VERSION}" \
      url="https://www.isc.org/kea/" \
      org.opencontainers.image.title="ISC Kea DHCP Server" \
      org.opencontainers.image.description="Kea is an open source implementation of the Dynamic Host Configuration Protocol (DHCP) servers" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.url="https://www.isc.org/kea/" \
      org.opencontainers.image.source="https://github.com/kometchtech/kea-docker"
