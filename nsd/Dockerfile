# syntax = docker/dockerfile:experimental

# ===== Common Build Base =====
FROM debian:latest AS common-build-base

# Common build environment and packages
ARG COMMON_BUILD="build-essential make gawk autoconf automake libtool curl binutils pkg-config"
ARG CFLAGS="-Os -fomit-frame-pointer"
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,--as-needed -rdynamic"

# Install common packages needed for all builds
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install ${COMMON_BUILD} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ===== Build Stage for NSD =====
FROM common-build-base AS build

# Build-specific packages
ARG VERSION
ARG BUILD_PKGS="libexpat1-dev libssl-dev libevent-dev zlib1g-dev bison libfl-dev \
		libprotobuf-c-dev protobuf-c-compiler libfstrm-dev"

# Install additional build packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install ${BUILD_PKGS} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create build directories and user
RUN mkdir -p /tmp/build /tmp/root/etc/nsd \
    && groupadd nsd \
    && useradd -g nsd -s /dev/null -d /etc nsd

# Download and extract NSD source with version tag
RUN curl -fsSL "https://www.nlnetlabs.nl/downloads/nsd/nsd-${VERSION}.tar.gz" -o nsd.tar.gz \
    && tar xf nsd.tar.gz --strip-components=1 -C /tmp/build \
    && rm -f nsd.tar.gz

# Compile and install
WORKDIR /tmp/build
RUN autoreconf -if \
    && ./configure \
      --prefix=/usr/local \
      --with-zonesdir=/etc/nsd/zones \
      --with-dbfile=/var/cache/nsd/zone.db \
      --with-xfrdfile=/var/cache/nsd/xfrd.state \
      --with-xfrdir=/var/cache/nsd \
      --sysconfdir=/etc \
      --disable-static \
      --with-user=nsd \
      --with-libevent \
      --with-ssl \
      --enable-ratelimit \
      --enable-packed \
      --enable-year2038 \
      CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" \
    && make -j$(nproc) \
    && make install DESTDIR=/tmp/root \
    && cp /tmp/root/etc/nsd/nsd.conf.sample /tmp/root/etc/nsd/nsd.conf


    # Remove unnecessary files to reduce image size
RUN find /tmp/root/usr/local/share/doc -type f -delete 2>/dev/null || true \
    && find /tmp/root/usr/local/share/man -type f -delete 2>/dev/null || true

# ===== Runtime Stage =====
FROM debian:stable-slim AS runtime

# Runtime dependencies
ENV RUN_PKGS="openssl libevent-2.1-7 ca-certificates ldnsutils tzdata tini libprotobuf-c1 libfstrm0"
ENV TZ=Asia/Tokyo
ENV PATH="/usr/local/sbin:/usr/local/bin:${PATH}"

# Setup runtime environment
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y --no-install-recommends install ${RUN_PKGS} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /usr/local/share/man/* \
    && mkdir -p /var/cache/nsd /var/run/nsd /etc/nsd/zones \
    && chmod -R 0755 /var/run/nsd \
    && chmod 1777 /tmp \
    && groupadd -r nsd \
    && useradd -r -g nsd -s /sbin/nologin -d /etc/nsd nsd

# Copy NSD from build stage
WORKDIR /etc/nsd
COPY --from=build /tmp/root/ /

# Add entrypoint script
COPY entrypoint.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/entrypoint.sh \
    && ldconfig / \
    && chmod -R 0755 /var/cache/nsd \
    && chmod 1777 /tmp \
    && chown -R nsd:nsd /var/cache/nsd /var/run/nsd /etc/nsd/zones

# Configure ports and signal
EXPOSE 53/tcp 53/udp 8952/tcp
STOPSIGNAL SIGTERM

# Set entrypoint and default command
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/sbin/entrypoint.sh"]
CMD ["nsd", "-d", "-c", "/etc/nsd/nsd.conf"]

# Label information (at the end to minimize impact on build caching)
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      description="NLnet Labs Name Server Daemon (NSD) - Authoritative DNS server" \
      url="https://nlnetlabs.nl/projects/nsd/about/"
