# syntax = docker/dockerfile:experimental
FROM arm64v8/alpine:latest AS build

# Environment
ENV VERSION 1.9.0
ARG BUILD_PKGS="build-base clang curl expat-dev libressl-dev libevent-dev flex-dev lld "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIC -FORTIFY_SOURCE=2 -fPIE "
ARG CXXFLAGS="${CFLAGS} "
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now -fuse-ld=lld "
ENV CC="clang"
ENV CXX="clang++"

# source build and install
#RUN --mount=type=cache,target=/var/cache/apk \
RUN apk add --update ${BUILD_PKGS}
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
      PKG_CONFIG=/usr/bin/pkg-config \
      CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" CXXFLAGS="${CFLAGS}" \
  && make -j"$(nproc)" \
  && make install DESTDIR=/tmp/root


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ARG RUN_PKGS="libressl libevent ca-certificates ldns-tools tzdata expat flex bison "
#RUN --mount=type=cache,target=/var/cache/apk \
RUN apk add --update --no-cache ${RUN_PKGS} \
    && rm -rf /var/cache/apk/* /usr/local/share/man/*
#    && adduser -DH unbound


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

# export TCP and UDP
EXPOSE 53/tcp 53/udp 853/TCP

# entrypoint
WORKDIR /etc/unbound
CMD ["/usr/local/sbin/run.sh"]

# Application execution related information
ADD ./run.sh /usr/local/sbin/
RUN ["chmod", "+x", "/usr/local/sbin/run.sh"]

# Fetch unbound and libraries from build image
COPY --from=build /tmp/root/ /
RUN ldconfig /
