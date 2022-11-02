FROM --platform=$TARGETPLATFORM debian:latest AS build

# Environment
ARG VERSION="1.9.2"
ARG BUILD_BASE="build-essential clang llvm lld gawk autoconf automake libtool "
ARG BUILD_PKGS="${BUILD_BASE} libexpat1-dev libssl-dev libevent-dev libfl-dev libhiredis-dev libsodium-dev libnghttp2-dev curl "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer "
ARG CXXFLAGS="${CFLAGS}  "
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "
ENV CC="clang" \
    CXX="clang++" \
    AR="llvm-ar" \
    NM="llvm-nm" \
    RANLIB="llvm-ranlib" \
    LD="ld.lld" \
    STRIP="llvm-strip"

# source build and install
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
  && apt-get -y -qqq install ${BUILD_PKGS}

# build
RUN mkdir -p /usr/src /tmp/root/etc/unbound \
  && curl -fsSL "https://www.nlnetlabs.nl/downloads/unbound/unbound-${VERSION}.tar.gz" -o unbound.tar.gz \
  && tar xf "unbound.tar.gz" --strip-components=1 -C /usr/src \
  && rm -f "unbound.tar.gz" \
  && groupadd _unbound \
  && useradd -g _unbound -s /dev/null -d /etc _unbound
RUN cd /usr/src \
  && ./configure \
      --prefix=/usr/local \
      --with-libevent \
#      --with-pthreads \
      --with-ssl \
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
      --with-libnghttp2 \
      --without-pthreads \
      --without-solaris-threads \
      PKG_CONFIG=/usr/bin/pkg-config \
      CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" CXXFLAGS="${CFLAGS}"
RUN cd /usr/src \
    && make -j"$(nproc)"
RUN cd /usr/src \
    && make strip \
    && make install DESTDIR=/tmp/root


# Intermediate container with runtime dependencies
FROM --platform=$TARGETPLATFORM debian:stable-slim AS runtime

# Install runtime dependencies
ARG RUN_PKGS="openssl libevent-2.1-7 ca-certificates ldnsutils tzdata expat flex bison libhiredis0.14 libsodium23  \
              libnghttp2-14 libexpat1 libprotobuf-c1 bsdmainutils "
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
	&& apt-get -y --no-install-recommends -qqq install ${RUN_PKGS}  \
    && apt-get clean \
    && rm -rf  \
		/tmp/* \
		/var/lib/apt/lists/* \
		/usr/local/share/man/* \
	&& groupadd _unbound \
    && useradd -g _unbound -s /dev/null -d /etc _unbound


# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="$TARGETPLATFORM" \
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
CMD ["unbound", "-d", "-c", "/etc/unbound/unbound.conf"]

# Fetch unbound and libraries from build image
COPY --from=build /tmp/root/ /
RUN ldconfig /

# Application execution related information
COPY ./entrypoint.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/entrypoint.sh