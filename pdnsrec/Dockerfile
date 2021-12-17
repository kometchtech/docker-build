# syntax = docker/dockerfile:experimental
FROM arm64v8/alpine:latest AS build

# Environmet
ARG VERSION="4.2.0"
ARG BUILD_BASE="alpine-sdk clang llvm lld gawk autoconf automake libtool curl "
ARG BUILD_PKGS="${BUILD_BASE} boost-dev lua5.3-dev libedit-dev libsodium-dev protobuf-dev gnutls-dev libatomic_ops-dev \
                net-snmp-dev fstrm-dev "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer "
ARG CXXFLAGS="${CFLAGS} "
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "
ENV CC="clang" \
    CXX="clang++" \
    AR="llvm-ar" \
    NM="llvm-nm" \
    RANLIB="llvm-ranlib" \
    LD="ld.lld" \
    STRIP="llvm-strip"

# dev package install
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --update ${BUILD_PKGS}
RUN mkdir -p /tmp/build
## build
RUN curl -fsSL "https://downloads.powerdns.com/releases/pdns-recursor-${VERSION}.tar.bz2" -o pdns-recursor.tar.bz2
RUN tar xf pdns-recursor.tar.bz2 --strip-components=1 -C /tmp/build \
    && rm pdns-recursor.tar.bz2
RUN cd /tmp/build \
    && ./configure \
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
      CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" \
    && make -j3 install-strip DESTDIR=/tmp/root
RUN rm -rf /tmp/root/usr/local/share/man/*
RUN ldconfig /


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ARG RUN_PKGS="boost-context boost-filesystem lua5.3-libs libedit protobuf libsodium tzdata gnutls libatomic \
              ca-certificates tini net-snmp fstrm "
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --update --no-cache ${RUN_PKGS} \
    && rm -rf /var/cache/apk/* /usr/local/share/man/* /var/tmp \
    && adduser -DH pdns-recursor \
    && mkdir -p /var/lib/pdns-recursor/nod /var/lib/pdns-recursor/udr


# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      description="The PowerDNS Recursor is a high-end, high-performance resolving \
                  name server which powers the DNS resolution of at least a hundred million \
                  subscribers." \
      url="https://www.powerdns.com/recursor.html"

# Environment
ENV TZ Asia/Tokyo

# service running
STOPSIGNAL SIGTERM

# export DNS over UDP
EXPOSE 53/UDP 
EXPOSE 53/TCP

# Application execution related information
COPY ./entrypoint.sh /usr/local/sbin/entrypoint.sh
RUN chmod +x /usr/local/sbin/entrypoint.sh

COPY --from=build /tmp/root/ /
RUN ldconfig /

# select ENTRYPOINT
WORKDIR /etc/powerdns
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/sbin/entrypoint.sh"]
CMD ["pdns_recursor", "--disable-syslog", "--log-timestamp=yes", "--config-dir=/etc/powerdns"]
