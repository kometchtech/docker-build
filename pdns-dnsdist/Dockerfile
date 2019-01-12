FROM arm64v8/alpine:latest AS build

# Env
ENV VERSION 1.3.3
ARG BUILD_PKGS="build-base pkgconf boost-dev lua5.3-dev libsodium-dev protobuf-dev re2-dev net-snmp-dev \
               libedit-dev gawk libressl-dev curl libressl-dev "
ARG CFLAGS="-fPIC -fPIE -DPIE -O2 -fstack-protector -pthread -fomit-frame-pointer -pipe -FORTIFY_SOURCE=2 \
            -ftree-vectorize -ftree-slp-vectorize "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"

# dev package install
RUN apk add --update --no-cache ${BUILD_PKGS}

## build
RUN mkdir -p /usr/src \
  && cd / \
  && curl -fSL "https://downloads.powerdns.com/releases/dnsdist-${VERSION}.tar.bz2" -o dnsdist.tar.bz2 \
  && tar xf dnsdist.tar.bz2 --strip-components=1 -C /usr/src \
  && rm dnsdist.tar.bz2 \
  && cd /usr/src \
  && ./configure \
    --prefix=/usr/local \
    --sysconfdir=/etc/dnsdist \
    --localstatedir=/var \
    --enable-libsodium \
    --enable-dnscrypt \
    --enable-dns-over-tls \
    --enable-re2 \
    --with-protobuf \
    --disable-static \
    --with-ebpf \
    --disable-dependency-tracking \
    CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
  && make -j4  \
  && make install-strip DESTDIR=/tmp/root
RUN mkdir -p /tmp/root/etc/dnsdist \
  && ldconfig / || true


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ARG RUN_PKGS="tzdata boost lua5.3 libsodium protobuf re2 net-snmp libedit libressl "
RUN apk add --update --no-cache ${RUN_PKGS} \
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

ENV TZ Asia/Tokyo

# Select entrypoint
EXPOSE 53/tcp 53/udp
VOLUME ["/etc/dnsdist"]
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
  && ldconfig / || true
RUN ldconfig / || true
