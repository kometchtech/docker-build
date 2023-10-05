# syntax = docker/dockerfile:experimental
FROM --platform=$TARGETPLATFORM debian:latest AS build

# Env
ARG VERSION="1.4.0-beta1"
ARG BUILD_BASE="build-essential binutils lld make gawk autoconf automake libtool curl "
ARG BUILD_PKGS="${BUILD_BASE} pkgconf libboost-dev lua5.1-dev libsodium-dev libprotobuf-c-dev libre2-dev libsnmp-dev \
               libedit-dev libssl-dev libnghttp2-dev "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-O3 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "
ENV LD="ld.lld"


# dev package install
RUN mkdir -p /usr/src /tmp/root/etc/dnsdist
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install ${BUILD_PKGS}
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
      --with-libsodium \
      --with-libssl \
      --enable-dnscrypt \
      --enable-dns-over-tls \
      --with-re2 \
      --with-protobuf \
      --with-ebpf \
      --disable-dependency-tracking \
      --with-nghttp2 \
      --with-net-snmp \
      CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}"
RUN cd /usr/src \
    && make -j2  \
    && make install-strip DESTDIR=/tmp/root
RUN ldconfig /
RUN rm -rf /tmp/root/usr/local/share/man/*


# Intermediate container with runtime dependencies
FROM --platform=$TARGETPLATFORM debian:stable-slim AS runtime

# Install runtime dependencies
ARG RUN_PKGS="tzdata liblua5.1-0 libsodium23 libprotobuf-c1 libre2-9 libsnmp-base libsnmp40 libedit2 openssl libnghttp2-14"
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install --no-install-recommends ${RUN_PKGS} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /usr/local/share/man/* \
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
EXPOSE 53/tcp 53/udp

# service running
STOPSIGNAL SIGTERM

# Volume
WORKDIR /etc/dnsdist

# Select entrypoint
COPY ["entrypoint.sh", "/usr/bin/"]
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["dnsdist", "--supervised", "--disable-syslog", "-u", "_dnsdist", "-g", "_dnsdist"]

# Fetch pdns-dnsdist libraries from build image
COPY --from=build /tmp/root/ /
RUN ldconfig /
