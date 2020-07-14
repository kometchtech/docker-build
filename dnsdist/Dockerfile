# syntax = docker/dockerfile:experimental
FROM arm64v8/alpine:latest AS build

# Env
ARG VERSION="1.4.0-beta1"
ARG BUILD_BASE="build-base binutils clang llvm lld make gawk autoconf automake libtool curl "
ARG BUILD_PKGS="${BUILD_BASE} pkgconf boost-dev lua5.3-dev libsodium-dev protobuf-dev re2-dev net-snmp-dev \
               libedit-dev openssl-dev "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "
ENV CC="clang" \
    CXX="clang++" \
    AR="llvm-ar" \
    NM="llvm-nm" \
    RANLIB="llvm-ranlib" \
    LD="ld.lld" \
    STRIP="llvm-strip"

# dev package install
RUN mkdir -p /usr/src /tmp/root/etc/dnsdist
RUN --mount=type=cache,target=/var/cache/apk \
  apk add --update  ${BUILD_PKGS}
## build
#RUN curl -fsSL "https://downloads.powerdns.com/autobuilt/dnsdist/${VERSION}/dnsdist-${VERSION}.tar.bz2" -o dnsdist.tar.bz2 \
RUN curl -fsSL "https://downloads.powerdns.com/releases/dnsdist-${VERSION}.tar.bz2" -o dnsdist.tar.bz2 \
    && tar xf dnsdist.tar.bz2 --strip-components=1 -C /usr/src \
    && rm dnsdist.tar.bz2
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
      CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
    && make -j"$(nproc)"  \
    && make install-strip DESTDIR=/tmp/root
RUN ldconfig /
RUN rm -rf /tmp/root/usr/local/share/man/*


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ARG RUN_PKGS="tzdata lua5.3-libs libsodium protobuf re2 net-snmp-libs libedit openssl net-snmp-agent-libs tini "
RUN --mount=type=cache,target=/var/cache/apk \
  apk add --update --no-cache ${RUN_PKGS} \
  && rm -rf /var/cache/apk/* /usr/local/share/man/* \
  && adduser -DH _dnsdist

# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
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
ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/entrypoint.sh"]
CMD ["dnsdist", "--supervised", "--disable-syslog", "-u", "_dnsdist", "-g", "_dnsdist"]

# Fetch pdns-dnsdist libraries from build image
COPY --from=build /tmp/root/ /
RUN set -x \
  && runDeps="$( \
    scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
      | tr ',' '\n' \
      | sort -u \
      | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
  )" \
  && apk add --no-cache -t .rundeps $runDeps \
  && ldconfig /
