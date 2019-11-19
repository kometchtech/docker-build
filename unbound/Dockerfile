# syntax = docker/dockerfile:experimental
FROM arm64v8/alpine:latest AS build

# Environment
ARG VERSION="1.9.2"
ARG BUILD_BASE="build-base binutils clang llvm lld make gawk autoconf automake libtool curl "
ARG BUILD_PKGS="${BUILD_BASE} expat-dev libressl-dev libevent-dev flex-dev hiredis-dev libsodium-dev "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer -D_FORTIFY_SOURCE=2 "
ARG CXXFLAGS="${CFLAGS} "
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "
ENV CC="clang"
ENV CXX="clang++"
ENV AR="llvm-ar"
ENV NM="llvm-nm"
ENV RANLIB="llvm-ranlib"
ENV LD="ld.lld"
ENV STRIP="llvm-strip"

# source build and install
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --update ${BUILD_PKGS}
# build
RUN mkdir -p /usr/src /tmp/root/etc/unbound \
  && curl -fsSL "https://www.nlnetlabs.nl/downloads/unbound/unbound-${VERSION}.tar.gz" -o unbound.tar.gz \
  && tar xf "unbound.tar.gz" --strip-components=1 -C /usr/src \
  && rm -f "unbound.tar.gz"
RUN cd /usr/src \
  && ./configure \
      --prefix=/usr/local \
      --with-libevent \
      --with-pthreads \
      --with-ssl \
      --disable-rpath \
      --sysconfdir=/etc/unbound \
      --with-conf-file=/etc/unbound/unbound.conf \
      --with-pidfile=/var/run/unbound.pid \
      --enable-subnet \
      --enable-sha2 \
      --disable-gost \
      --disable-ecdsa \
      --enable-pie \
      --enable-relro-now \
      --enable-tfo-server \
      --enable-tfo-client \
      --enable-cachedb \
      --with-libhiredis \
      --enable-dnscrypt \
      PKG_CONFIG=/usr/bin/pkg-config \
      CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" CXXFLAGS="${CFLAGS}" \
  && make -j"$(nproc)" \
  && make strip \
  && make install DESTDIR=/tmp/root


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ARG RUN_PKGS="libressl libevent ca-certificates ldns-tools tzdata expat flex bison hiredis libsodium "
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --update --no-cache ${RUN_PKGS} \
    && rm -rf /var/cache/apk/* /usr/local/share/man/* \
    && adduser -DH unbound


# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      description="Unbound is a validating, recursive, caching DNS resolver. \
                  It is designed to be fast and lean and incorporates modern features \
                  based on open standards." \
      url="https://nlnetlabs.nl/projects/unbound/about/"

# Environment
ENV TZ Asia/Tokyo

# publish port TCP and UDP
EXPOSE 53/tcp 53/udp 853/TCP

# service running
STOPSIGNAL SIGTERM

# entrypoint
WORKDIR /etc/unbound
ENTRYPOINT ["/usr/local/sbin/entrypoint.sh"]

# Application execution related information
ADD ./entrypoint.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/entrypoint.sh

# Fetch unbound and libraries from build image
COPY --from=build /tmp/root/ /
RUN ldconfig /
