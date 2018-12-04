FROM arm64v8/alpine:latest AS build

# Environment
ENV UNBOUND_VERSION 1.8.2
ARG BUILD_PKGS="build-base curl expat-dev libressl-dev libevent-dev gawk flex-dev "
ENV CFLAGS "-O2 -fPIE -DPIE --param ssp-buffer-size=4 -fstack-protector -fomit-frame-pointer -pipe"
ENV CXXFLAGS "${CFLAGS}"
ENV LDFLAGS "-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"

# source build and install
RUN apk add --update --no-cache -t .build-deps ${BUILD_PKGS} \ 
  && mkdir -p /usr/src \
  && curl -fL "https://www.nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz" -o unbound.tar.gz \
  && tar xf "unbound.tar.gz" --strip-components=1 -C /usr/src \
  && rm -f "unbound.tar.gz" \ 
  && cd /usr/src \
  && ./configure \
      --prefix=/usr/local \
      --with-libevent \
      --with-pthreads \
      --with-ssl \
      --disable-rpath \
      --sysconfdir=/etc/unbound \
      --with-conf-file=/etc/unbound/unbound.conf \
      --with-pidfile=/var/run/unbound.pid \
      PKG_CONFIG=/usr/bin/pkg-config \
      --enable-subnet \
      --enable-sha2 \
      --disable-gost \
      --disable-ecdsa \
      --enable-pie \
      --disable-flto \
      --enable-relro-now \
      CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" CXXFLAGS="${CFLAGS}" \
  && make -j "$(nproc)" \
  && make install DESTDIR=/tmp/root 
RUN mkdir -p /tmp/root/etc/unbound \
  && ldconfig / || true


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ARG RUN_PKGS="libressl libevent ca-certificates ldns-tools tzdata expat flex bison "
RUN apk add --no-cache ${RUN_PKGS} \
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

ENV TZ Asia/Tokyo 

# export TCP and UDP
EXPOSE 53/tcp 53/udp 853/TCP

# entrypoint
CMD ["/usr/local/sbin/run.sh"]

# Application execution related information
ADD ./run.sh /usr/local/sbin/
RUN ["chmod", "+x", "/usr/local/sbin/run.sh"]
VOLUME ["/etc/unbound", "/var/run/unbound"]

# Fetch unbound and libraries from build image
COPY --from=build /tmp/root/ /
RUN ldconfig / || true
