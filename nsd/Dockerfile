# syntax = docker/dockerfile:experimental
FROM debian:latest AS build

# Environment
ARG VERSION
ARG BUILD_BASE="build-essential make gawk autoconf automake libtool curl binutils "
ARG BUILD_PKGS="${BUILD_BASE} libexpat1-dev libssl-dev libevent-dev zlib1g-dev bison libfl-dev "
ARG CFLAGS="-Os -fomit-frame-pointer "
ARG CXXFLAGS="${CFLAGS} "
ARG LDFLAGS="-Wl,--as-needed -rdynamic "

# source build and install
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install ${BUILD_PKGS} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* 

# build
RUN mkdir -p /tmp/build /tmp/root/etc/nsd
RUN curl -fsSL "https://www.nlnetlabs.nl/downloads/nsd/nsd-${VERSION}.tar.gz" -o nsd.tar.gz \
    && tar xf "nsd.tar.gz" --strip-components=1 -C /tmp/build \
    && rm -f "nsd.tar.gz" \
    && groupadd nsd \
    && useradd -g nsd -s /dev/null -d /etc nsd
RUN cd /tmp/build \
    && autoreconf -if \
    && ./configure \
      --prefix=/usr/local \
      --with-zonesdir=/etc/nsd/zones \
      --with-dbfile=/var/cache/nsd/zone.db \
      --with-xfrdfile=/var/cache/nsd/xfrd.state \
      --sysconfdir=/etc \
      --disable-static \
      --with-user=nsd \
      --with-libevent \
      --with-ssl \
      --enable-ratelimit \
      --enable-packed \
      CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
    && make -j$(nproc) \
    && make install DESTDIR=/tmp/root
RUN cp /tmp/root/etc/nsd/nsd.conf.sample /tmp/root/etc/nsd/nsd.conf


# Intermediate container with runtime dependencies
FROM debian:stable-slim AS runtime

# Add labels
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      description="NLnet Labs Name Server Daemon (NSD) - Authoritative DNS server" \
      url="https://nlnetlabs.nl/projects/nsd/about/"

# Install runtime dependencies
ENV RUN_PKGS="openssl libevent-2.1-7 ca-certificates ldnsutils tzdata tini"
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y --no-install-recommends install ${RUN_PKGS} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /usr/local/share/man/* \
    && mkdir -p /var/cache/nsd /var/run/nsd /etc/nsd/zones \
    && chmod -R 0777 /var/run/nsd \
    && groupadd -r nsd \
    && useradd -r -g nsd -s /sbin/nologin -d /etc/nsd nsd

WORKDIR /etc/nsd
# Copy NSD from build stage
COPY --from=build /tmp/root/ /

# Set up environment and configuration
ENV TZ=Asia/Tokyo
EXPOSE 53/tcp 53/udp 8952/tcp
STOPSIGNAL SIGTERM

# Add entrypoint script
COPY entrypoint.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/entrypoint.sh

# Set permissions and ownership
RUN ldconfig / \
    && chmod -R 0777 /tmp /var/cache/nsd \
    && chown -R nsd:nsd /var/cache/nsd /var/run/nsd /etc/nsd/zones

# Set entrypoint and default command
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/sbin/entrypoint.sh"]
CMD ["nsd", "-d", "-c", "/etc/nsd/nsd.conf"]
