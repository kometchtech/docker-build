# syntax = docker/dockerfile:experimental
FROM --platform=$TARGETPLATFORM rust:latest AS build

# Environment
ARG VERSION="4.2.0"
ARG BUILD_PKGS="build-essential mold gawk autoconf automake libtool curl libboost-all-dev liblua5.3-dev libedit-dev libsodium-dev libprotobuf-dev libgnutls28-dev libatomic-ops-dev libsnmp-dev libfstrm-dev libcurl4"
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer -fuse-ld=mold"
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now"

# Dev package install and build
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    apt-get install -y --no-install-recommends ${BUILD_PKGS} && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /tmp/build && \
    curl -fsSL "https://downloads.powerdns.com/releases/pdns-recursor-${VERSION}.tar.bz2" | tar xj --strip-components=1 -C /tmp/build && \
    cd /tmp/build && \
    ./configure \
      --prefix=/usr/local \
      --sysconfdir=/etc/powerdns \
      --localstatedir=/var \
      --libdir=${prefix}/lib/aarch64-linux-gnu \
      --libexecdir=${prefix}/lib/aarch64-linux-gnu \
      --disable-static \
      --with-net-snmp \
      --with-service-group=pdns-recursor \
      --with-service-user=pdns-recursor \
      --with-lua \
      --enable-dns-over-tls \
      CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" && \
    make -j$(( $(nproc) > 6 ? 6 : $(nproc) )) install DESTDIR=/tmp/root && \
    make clean && \
    strip /tmp/root/usr/local/bin/* /tmp/root/usr/local/sbin/* && \
    rm -rf /tmp/root/usr/local/share/man/* && \
    ldconfig /


# Intermediate container with runtime dependencies
FROM --platform=$TARGETPLATFORM debian:stable-slim AS runtime

# Install runtime dependencies
ARG RUN_PKGS="libboost-context1.74.0 libboost-filesystem1.74.0 liblua5.3-0 libedit2 libprotobuf32 libsodium23 tzdata libgnutls30 \
              libatomic1 ca-certificates tini libsnmp40 libfstrm0 tini libcurl4 libboost-system1.74.0 libboost-thread1.74.0"
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install --no-install-recommends ${RUN_PKGS} \
    && groupadd pdns-rec \
    && useradd -g pdns-rec -s /dev/null -d /etc pdns-rec \
    && apt-get clean \
    && apt-get purge -y --auto-remove ${BUILD_PKGS} \
    && rm -rf /var/lib/apt/lists/* /usr/local/share/man/* /var/tmp \
    && mkdir -p /var/lib/pdns-recursor/nod /var/lib/pdns-recursor/udr


# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="$TARGETPLATFORM" \
      description="The PowerDNS Recursor is a high-end, high-performance resolving \
                  name server which powers the DNS resolution of at least a hundred million \
                  subscribers." \
      url="https://www.powerdns.com/recursor.html"

# Environment
ENV TZ Asia/Tokyo

# service running
STOPSIGNAL SIGTERM

# expose webserver port
EXPOSE 8082
# expose DNS over UDP/TCP
EXPOSE 53/UDP 
EXPOSE 53/TCP

# select ENTRYPOINT
WORKDIR /etc/powerdns
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/sbin/entrypoint.sh"]
CMD ["pdns_recursor", "--disable-syslog", "--log-timestamp=yes", "--config-dir=/etc/powerdns"]

# copy build binary
COPY --from=build /tmp/root/ /
RUN ldconfig /

# Application execution related information
COPY ./entrypoint.sh /usr/local/sbin/entrypoint.sh
RUN chmod +x /usr/local/sbin/entrypoint.sh

