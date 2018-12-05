FROM arm64v8/alpine:latest AS build

# Environment
ENV NSD_VERSION 4.1.26
ARG BUILD_PKGS="build-base curl automake autoconf expat-dev libressl-dev libevent-dev "
ENV CFLAGS "-O2 -fstack-protector -pthread -fomit-frame-pointer -pipe -fPIC "
ENV LDFLAGS "-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"

# source build and install
RUN apk add --update --no-cache ${BUILD_PKGS} \
    && mkdir -p /tmp/build \
    && curl -fSL "https://www.nlnetlabs.nl/downloads/nsd/nsd-${NSD_VERSION}.tar.gz" -o nsd.tar.gz \
    && tar xf "nsd.tar.gz" --strip-components=1 -C /tmp/build \
    && rm -f "nsd.tar.gz" \ 
    && cd /tmp/build \
    && autoreconf -if \
    && ./configure \
      --prefix=/usr/local \
      --with-zonesdir=/usr/local/etc/nsd/zones \
      --sysconfdir=/etc \
      --with-libevent \
      --with-ssl \
      --disable-flto \
      --enable-ratelimit \
      --enable-packed \
      CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
	&& make -j"$(nproc)" install DESTDIR=/tmp/root 
RUN mkdir -p /tmp/root/etc/nsd \
    && cp /tmp/root/etc/nsd/nsd.conf.sample /tmp/root/etc/nsd/nsd.conf \
    && ldconfig / || true 


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ENV RUN_PKGS "libressl libevent ca-certificates ldns-tools tzdata"
RUN apk add --update --no-cache ${RUN_PKGS} \
     && rm -rf /var/cache/apk/* /usr/local/share/man/* \
     && adduser -DH nsd

# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      description="The NLnet Labs Name Server Daemon (NSD) is \
      an authoritative DNS name server. It has been developed for operations \
      in environments where speed, reliability, stability and security are \
      of high importance." \
      url="https://nlnetlabs.nl/projects/nsd/about/"

ENV TZ Asia/Tokyo

# Application execution related information
COPY ./run.sh /usr/local/sbin/run.sh
VOLUME ["/usr/local/etc/nsd", "/usr/local/etc/nsd/zones", "/usr/local/var/db/nsd"]

# export TCP and UDP
EXPOSE 53/tcp 53/udp 8952/tcp
RUN ["chmod", "+x", "/usr/local/sbin/run.sh"]
CMD ["/usr/local/sbin/run.sh"]

# Fetch nsd libraries from build image
COPY --from=build /tmp/root/ /
RUN ldconfig / || true
RUN mkdir -p /var/cache/nsd /var/run/nsd /usr/local/etc/nsd/zones \
    && chmod 0700 /usr/local/var/db/nsd /var/run/nsd /var/cache/nsd \
    && chmod 0777 /tmp

