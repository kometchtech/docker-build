# syntax = docker/dockerfile:experimental
FROM --platform=$TARGETPLATFORM debian:latest AS build

# Env
ENV USE_CCACHE=1
ENV CCACHE_DIR=/root/.ccache
ENV set CC='ccache gcc'
ARG VERSION
ARG BUILD_BASE="build-essential binutils make gawk autoconf automake libtool curl ccache"
ARG BUILD_PKGS="${BUILD_BASE} pkgconf libboost-dev lua5.1-dev libsodium-dev libprotobuf-c-dev libre2-dev libsnmp-dev libluajit-5.1-dev \
               libedit-dev libssl-dev libnghttp2-dev libgnutls28-dev libxdp-dev libbpf-dev ca-certificates libh2o-evloop-dev "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-O3 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "

# dev package install
RUN apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${BUILD_PKGS} \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /usr/src /tmp/root/etc/dnsdist
## build
RUN curl -fsSL "https://downloads.powerdns.com/releases/dnsdist-${VERSION}.tar.bz2" -o dnsdist.tar.bz2 \
    && tar xf dnsdist.tar.bz2 --strip-components=1 -C /usr/src \
    && rm dnsdist.tar.bz2 \
    && groupadd _dnsdist \
    && useradd -g _dnsdist -s /dev/null -d /etc _dnsdist
RUN cd /usr/src \
    && ./configure \
      --prefix=/usr/local \
      --sysconfdir=/etc/dnsdist \
      --localstatedir=/var \
      --enable-lto=thin \
      --with-libsodium \
      --with-libssl \
      --with-gnutls \
      --enable-dnscrypt \
      --enable-dns-over-tls \
      --enable-dns-over-https \
#      --enable-dns-over-quic \
      --with-re2 \
      --with-protobuf \
      --with-ebpf \
      --with-xsk \
      --disable-dependency-tracking \
      --with-nghttp2 \
      --with-net-snmp \
      --with-lua \
      --disable-shared \
      --enable-static \
      CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}"
RUN cd /usr/src \
    && make -j2 \
    && make install-strip DESTDIR=/tmp/root
RUN ldconfig /
RUN rm -rf /tmp/root/usr/local/share/man/*


# Intermediate container with runtime dependencies
FROM --platform=$TARGETPLATFORM debian:stable-slim AS runtime

# Install runtime dependencies
ARG RUN_PKGS="tzdata liblua5.1-0 libsodium23 libprotobuf-c1 libre2-9 libsnmp-base libsnmp40 libedit2 openssl \
	      libnghttp2-14 libgnutls30 libxdp1 libbpf1 libh2o-evloop0.13 libluajit-5.1-2 "
RUN apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${RUN_PKGS} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd _dnsdist \
    && useradd -g _dnsdist -s /dev/null -d /etc _dnsdist


# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="$TARGETPLATFORM" \
      description="dnsdist is a highly DNS-, DoS- and abuse-aware loadbalancer. \
                  Its goal in life is to route traffic to the best server, delivering top \
                  performance to legitimate users while shunting or blocking abusive traffic." \
      url="https://dnsdist.org/"

# Environment
ENV TZ Asia/Tokyo

# Publish port
EXPOSE 53/tcp 53/udp 443/tcp 853/tcp 8083/tcp 8443/tcp 8443/udp

# service running
STOPSIGNAL SIGTERM

# Volume
WORKDIR /etc/dnsdist

# Select entrypoint
COPY ["entrypoint.sh", "/usr/bin/"]
HEALTHCHECK CMD ["dnsdist", "-e", "showVersion()", "||", "exit", "1"]
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["dnsdist", "--supervised", "--disable-syslog", "-u", "_dnsdist", "-g", "_dnsdist"]

# Fetch pdns-dnsdist libraries from build image and update ldconfig
COPY --from=build /tmp/root/ /
RUN ldconfig

