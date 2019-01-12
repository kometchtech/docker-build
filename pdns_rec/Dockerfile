FROM arm64v8/alpine:latest AS build

# Environmet
ENV VERSION 4.1.8
ARG BUILD_PKGS="build-base libressl-dev boost-dev lua5.3-dev libedit-dev libsodium-dev protobuf-dev \
                curl gawk "
ARG CFLAGS="-O2 -fstack-protector -pthread -heap-arrays -pipe -fPIC -FORTIFY_SOURCE=2 -fPIE \
            -fomit-frame-pointer -ftree-vectorize -ftree-slp-vectorize "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"

# dev package install
RUN apk add --update --no-cache ${BUILD_PKGS} 
RUN mkdir -p /tmp/build 
## build
WORKDIR /
RUN curl -fsSL "https://downloads.powerdns.com/releases/pdns-recursor-${VERSION}.tar.bz2" -o pdns-recursor.tar.bz2
RUN tar xf pdns-recursor.tar.bz2 --strip-components=1 -C /tmp/build \
  && rm pdns-recursor.tar.bz2 \
  && cd /tmp/build \
  && ./configure \
     --prefix=/usr/local \
     --sysconfdir=/etc/powerdns \
     --localstatedir=/var \
     --libdir=${prefix}/lib/aarch64-linux-gnu \
     --libexecdir=${prefix}/lib/aarch64-linux-gnu \
     --disable-dependency-tracking \
     --disable-static \
     --enable-libsodium \
     --with-protobuf \
     --with-lua \
     CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" \
  && make -j4 install-strip DESTDIR=/tmp/root
RUN rm -rf /tmp/root/usr/local/share/man/* \
  && ldconfig / || true


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ENV RUN_PKGS "lua5.3 libedit protobuf libsodium boost tzdata libressl ca-certificates "
RUN apk add --update --no-cache ${RUN_PKGS} \
    && rm -rf /var/cache/apk/* /usr/local/share/man/* /var/tmp
RUN adduser -DH pdnsrec


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

# export DNS over UDP
EXPOSE 53/UDP 53/TCP

# select ENTRYPOINT
VOLUME ["/etc/powerdns"]
CMD ["/usr/local/sbin/pdns_recursor", "--disable-syslog", "--log-timestamp=yes"]

COPY --from=build /tmp/root/ /
RUN ldconfig / || true
