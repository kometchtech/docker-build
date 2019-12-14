# syntax = docker/dockerfile:experimental
FROM arm64v8/alpine:latest AS build

# Environment
ARG VERSION=4.2.0
ARG BUILD_BASE="build-base binutils clang llvm make gawk autoconf automake libtool curl lld "
ARG BUILD_PKGS="${BUILD_BASE} expat-dev libressl-dev libevent-dev "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer -D_FORTIFY_SOURCE=2 "
ARG CXXFLAGS="${CFLAGS} "
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "
ENV CC="clang" \
    CXX="clang++" \
    AR="llvm-ar" \
    NM="llvm-nm" \
    RANLIB="llvm-ranlib" \
    LD="ld.lld" \
    STRIP="llvm-strip"

# source build and install
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --update ${BUILD_PKGS}
RUN mkdir -p /tmp/build /tmp/root/etc/nsd
RUN curl -fsSL "https://www.nlnetlabs.nl/downloads/nsd/nsd-${VERSION}.tar.gz" -o nsd.tar.gz \
    && tar xf "nsd.tar.gz" --strip-components=1 -C /tmp/build \
    && rm -f "nsd.tar.gz"
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
    && make -j"$(nproc)" \
    && make install DESTDIR=/tmp/root
RUN cp /tmp/root/etc/nsd/nsd.conf.sample /tmp/root/etc/nsd/nsd.conf


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ENV RUN_PKGS "libressl libevent ca-certificates ldns-tools tzdata"
RUN --mount=type=cache,target=/var/cache/apk \
       apk add --update --no-cache ${RUN_PKGS} \
    && rm -rf /var/cache/apk/* /usr/local/share/man/* \
    && adduser -DH nsd \
    && mkdir -p /var/cache/nsd /var/run/nsd /etc/nsd/zones \
    && chmod -R 0666 /var/run/nsd

# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      description="The NLnet Labs Name Server Daemon (NSD) is an authoritative DNS \
                  name server. It has been developed for operations in environments \
                  where speed, reliability, stability and security are of high importance." \
      url="https://nlnetlabs.nl/projects/nsd/about/"

# Environment
ENV TZ Asia/Tokyo

# publish port TCP and UDP
EXPOSE 53/tcp 53/udp 8952/tcp

# service running
STOPSIGNAL SIGTERM

# Execute app
WORKDIR /etc/nsd
ENTRYPOINT ["/usr/local/sbin/entrypoint.sh"]

# Application execution related information
ADD ./entrypoint.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/entrypoint.sh

# Fetch nsd libraries from build image
COPY --from=build /tmp/root/ /
RUN ldconfig / \
    && chmod -R 0777 /tmp /var/cache/nsd \
    && chown -R nsd:nsd /var/cache/nsd /var/run/nsd /etc/nsd/zones

