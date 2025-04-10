# syntax = docker/dockerfile:experimental
FROM debian:stable AS build

# Environment variables for build configuration
ARG VERSION
ARG BUILD_PKGS="build-essential gawk autoconf automake libtool xz-utils curl ldnsutils \
                libssl-dev libcap-dev libperl-dev libedit-dev libreadline-dev libncurses-dev libjemalloc-dev libidn2-dev libfstrm-dev \
                libxml2-dev libjson-c-dev libbsd-dev libuv1-dev libstdc++-11-pic libc6 libnghttp2-dev liburcu-dev ca-certificates \
                libmaxminddb-dev liblmdb-dev libkrb5-dev libgssapi-krb5-2 zlib1g-dev"
ARG CFLAGS="-Os -fomit-frame-pointer"
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,--as-needed"

# Install build dependencies and build BIND in a single layer to reduce image size
RUN set -ex \
    && DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get install -y --no-install-recommends ${BUILD_PKGS} \
    && mkdir -p /tmp/build \
    && curl -fsSL "https://downloads.isc.org/isc/bind9/${VERSION}/bind-${VERSION}.tar.xz" | tar xJ --strip-components=1 -C /tmp/build \
    && cd /tmp/build \
    && ./configure \
        --prefix=/usr/local \
        --sysconfdir=/etc/named \
        --localstatedir=/var \
        --enable-shared \
        --disable-static \
        --with-gssapi \
        --with-libidn2 \
        --with-json-c \
        --with-lmdb \
        --with-gnu-ld \
        --with-maxminddb \
        --enable-fixed-rrset \
        --with-zlib \
        CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" \
    && make -j$(nproc) \
    && make install DESTDIR=/tmp/root \
    && ldconfig / \
    && mkdir -p /tmp/root/var/cache/named \
    && rm -rf /tmp/root/var/run /tmp/root/usr/local/share/man/* \
    && curl -fsSL "https://www.internic.net/domain/named.root" -o /tmp/root/var/cache/named/named.ca \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/* /tmp/build

# Intermediate container with runtime dependencies
FROM debian:stable-slim AS runtime

# Install runtime dependencies
ARG RUN_PKGS="libprotobuf-c1 tzdata openssl libcap2 libjson-c5 libxml2 libuv1 libnghttp2-14 liburcu8 tini libjemalloc2 libidn2-0 \
              libfstrm0 liblmdb0 libmaxminddb0 libkrb5-3 libgssapi-krb5-2 zlib1g"

RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install --no-install-recommends ${RUN_PKGS} \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /usr/local/share/man/* /var/lib/apt/lists/* \
    # Add non-root user for BIND
    && groupadd -r _named \
    && useradd -r -g _named -s /dev/null -d /etc _named \
    && mkdir -p /etc/named /var/cache/named /var/run/named /var/cache/named/dynamic /var/cache/named/pri

# Final container
FROM runtime

# Metadata
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      org.opencontainers.image.title="BIND DNS Server" \
      org.opencontainers.image.description="BIND is open source software that enables you to publish your \
                  Domain Name System (DNS) information on the Internet, and to \
                  resolve DNS queries for your users. The name BIND stands for \
                  Berkeley Internet Name Domain, because the software originated \
                  in the early 1980s at the University of California at Berkeley." \
      org.opencontainers.image.url="https://www.isc.org/downloads/bind/" \
      org.opencontainers.image.source="https://github.com/isc-projects/bind9"

# Environment
ENV TZ=Asia/Tokyo

# Expose DNS ports (TCP & UDP) and control port
EXPOSE 53/tcp 53/udp 953/tcp

# Service management
STOPSIGNAL SIGTERM

# Copy BIND binaries and configurations from build stage
COPY --from=build /tmp/root/ /
COPY ./named.conf /etc/named/named.conf
COPY ./local.rev ./local.zone /var/cache/named/pri/

# Set proper permissions
RUN chown -R _named:_named /var/cache/named /etc/named /var/run/named /var/cache/named/dynamic \
    && chmod 0750 /etc/named /var/cache/named /var/run/named \
    && ldconfig /

# Copy and setup entrypoint script
COPY ./entrypoint.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/entrypoint.sh

# Working directory and execution
WORKDIR /etc/named
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/sbin/entrypoint.sh"]
CMD ["/usr/local/sbin/named", "-c", "/etc/named/named.conf", "-g", "-u", "_named"]
