# syntax = docker/dockerfile:experimental
FROM arm64v8/alpine:latest AS build

# Environment
ENV VERSION 4.1.27
ARG BUILD_PKGS="build-base clang curl automake autoconf expat-dev libressl-dev libevent-dev lld "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIC -FORTIFY_SOURCE=2 -fPIE "
ARG CXXFLAGS="${CFLAGS} "
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now -fuse-ld=lld "
ENV CC="clang"
ENV CXX="clang++"

# source build and install
#RUN --mount=type=cache,target=/var/cache/apk \
RUN apk add --update ${BUILD_PKGS}
RUN mkdir -p /tmp/build /tmp/root/etc/nsd
RUN curl -fSL "https://www.nlnetlabs.nl/downloads/nsd/nsd-${VERSION}.tar.gz" -o nsd.tar.gz \
    && tar xf "nsd.tar.gz" --strip-components=1 -C /tmp/build \
    && rm -f "nsd.tar.gz"
RUN cd /tmp/build \
    && autoreconf -if \
    && ./configure \
      --prefix=/usr/local \
      --with-zonesdir=/usr/local/etc/nsd/zones \
      --sysconfdir=/etc \
      --with-libevent \
      --with-ssl \
      --enable-ratelimit \
      --enable-packed \
      CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
    && make -j"$(nproc)" install DESTDIR=/tmp/root
RUN cp /tmp/root/etc/nsd/nsd.conf.sample /tmp/root/etc/nsd/nsd.conf


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ENV RUN_PKGS "libressl libevent ca-certificates ldns-tools tzdata"
#RUN --mount=type=cache,target=/var/cache/apk \
RUN apk add --update --no-cache ${RUN_PKGS} \
    && rm -rf /var/cache/apk/* /usr/local/share/man/* \
#    && adduser -DH nsd \
    && mkdir -p /var/cache/nsd /var/run/nsd /usr/local/etc/nsd/zones /usr/local/var/db/nsd
#    && chown -R nsd:nsd /var/cache/nsd /var/run/nsd /usr/local/etc/nsd/zones /usr/local/var/db/nsd

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
ENTRYPOINT ["/usr/local/sbin/run.sh"]

# Application execution related information
ADD ./run.sh /usr/local/sbin/run.sh
RUN ["chmod", "+x", "/usr/local/sbin/run.sh"]

# Fetch nsd libraries from build image
COPY --from=build /tmp/root/ /
RUN ldconfig / \
    && chmod -R 0644 /usr/local/var/db/nsd /var/run/nsd /var/cache/nsd /usr/local/var/db/nsd/ \
    && chmod 0777 /tmp

