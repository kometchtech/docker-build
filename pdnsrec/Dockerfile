# syntax = docker/dockerfile:experimental
FROM arm64v8/alpine:latest AS build

# Environmet
ARG VERSION="4.2.0-rc1"
ARG BUILD_PKGS="build-base clang libressl-dev boost-dev lua5.3-dev libedit-dev libsodium-dev protobuf-dev \
                curl gawk lld "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIC -fPIE "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now -fuse-ld=lld "
ENV CC="clang"
ENV CXX="clang++"

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
      --disable-dependency-tracking \
      --enable-libsodium \
      --with-protobuf \
      --with-lua \
      CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" \
    && make -j4 install-strip DESTDIR=/tmp/root
RUN ldconfig /
RUN rm -rf /tmp/root/usr/local/share/man/*


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ARG RUN_PKGS="boost-context lua5.3-libs libedit protobuf libsodium tzdata libressl2.7-libssl ca-certificates "
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --update --no-cache ${RUN_PKGS} \
    && rm -rf /var/cache/apk/* /usr/local/share/man/* /var/tmp \
    && adduser -DH pdnsrec


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
EXPOSE 53/UDP 53/TCP

# select ENTRYPOINT
WORKDIR /etc/powerdns
CMD ["pdns_recursor", "--disable-syslog", "--log-timestamp=yes"]

COPY --from=build /tmp/root/ /
RUN ldconfig /
