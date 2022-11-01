# syntax = docker/dockerfile:experimental

FROM --platform=$TARGETPLATFORM alpine:latest AS gnutls-build

ARG MAJOR_VERSION="3.6"
ARG GNUTLS_VERSION="${MAJOR_VERSION}.16"
ARG BUILD_BASE="alpine-sdk lld gawk autoconf automake libtool xz"
ARG BUILD_PKGS="${BUILD_BASE} openssl-dev gmp-dev libgmpxx libtasn1-dev p11-kit-dev libidn2-dev \
				zlib-dev unbound-dev unbound-libs libunistring-dev libc6-compat libgcc nettle-dev "
ENV LD="ld.lld"

# build dependencies install
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache --update ${BUILD_PKGS} --allow-untrusted
RUN mkdir -p /usr/src /tmp/root
# app build
RUN curl -fSsL http://www.ring.gr.jp/pub/net/gnupg/gnutls/v${MAJOR_VERSION}/gnutls-${GNUTLS_VERSION}.tar.xz \
    -o gnutls.tar.xz \
    && tar xf gnutls.tar.xz --strip-components=1 -C /usr/src \
    && rm -f gnutls.tar.xz
RUN ln -s /lib/libc.musl-aarch64.so.1 /lib/libc.musl-aarch64.so.2
RUN cd /usr/src \
    && ./configure \
       --disable-doc \
       --disable-tests \
       --enable-shared \
       --disable-tools \
       --disable-guile \
       --disable-srp-authentication \
       --disable-psk-authentication \
       --disable-anon-authentication \
       --enable-openssl-compatibility \
       --disable-dtls-srtp-support \
       --disable-alpn-support \
       --disable-heartbeat-support \
       --without-p11-kit \
       --without-tpm
RUN cd /usr/src \
	&& make -j"$(nproc)" \
    && make check install \
	&& make install DESTDIR=/tmp/root
RUN cd /tmp/root/usr/local/lib


FROM --platform=$TARGETPLATFORM alpine:latest AS getdns-build
ARG GETDNS_VERSION="1.7.0"
ARG BUILD_BASE="build-base binutils lld make gawk autoconf automake libtool curl cmake "
ARG BUILD_PKGS="${BUILD_BASE} git yaml-dev linux-headers libuv-dev libev-dev check-dev unbound-dev \
                libevent-dev libidn2-dev libtasn1-dev libc6-compat libgcc nettle-dev openssl-dev "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now -fuse-ld=lld "
ENV LD="ld.lld"

# build dependencies install
COPY --from=gnutls-build /tmp/root/usr/local/ /usr/local/
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache --update ${BUILD_PKGS} --allow-untrusted
RUN mkdir -p \
        /usr/src \
        /tmp/root/var/stubby/ \
        /tmp/root/etc/stubby/ \
        /tmp/root/usr/local/lib/ \
        /tmp/root/usr/local/include
# app build
RUN git clone -b v${GETDNS_VERSION} --depth 1 https://github.com/getdnsapi/getdns.git /usr/src
RUN cd /usr/src \
    && git submodule update --init \
    && mkdir build
RUN cd /usr/src/build \
    && cmake \
       -DENABLE_SYSTEMD=OFF \
       -DENABLE_STATIC=OFF \
       -DBUILD_STUBBY=ON \
       -DSTUB_NATIVE_DNSSEC=ON \
       -DEDNS_COOKIES=ON \
       -DBUILD_LIBEV=ON \
       -DBUILD_LIBEVENT2=ON \
       -DBUILD_LIBUV=ON \
       -DUSE_LIBIDN2=ON \
       -DUSE_GNUTLS=ON \
       ..
RUN cd /usr/src/build \
    && make -j"$(nproc)" \
    && make install
RUN ldconfig /
# Copy libgetdns, libgetdns_ext_ev, libgetdns_ext_uv
RUN cp -r /usr/local/lib/* /tmp/root/usr/local/lib/ \
    && cp -r /usr/local/include/* /tmp/root/usr/local/include/ \
    && rm -rf /tmp/root/var/run /tmp/root/usr/local/share/man/*


# Intermediate container with runtime dependencies
FROM --platform=$TARGETPLATFORM alpine:latest AS runtime
# Install runtime dependencies
COPY --from=gnutls-build /tmp/root/usr/local/lib /usr/local/lib
ENV RUN_PKGS "tzdata yaml libuv libev libevent unbound-libs tini libidn2 libtasn1 nettle openssl "
RUN apk add --update --no-cache ${RUN_PKGS} --allow-untrusted \
    && rm -rf /var/cache/apk/* /usr/local/share/* \
    && mkdir -p /var/cache/stubby
RUN ldconfig /


# build stubby
FROM getdns-build AS build

ARG VERSION="0.2.6"
ARG BUILD_BASE="build-base binutils make gawk autoconf automake libtool curl "
ARG BUILD_PKGS="${BUILD_BASE} yaml unbound git "

RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache --update ${BUILD_PKGS} --allow-untrusted
# build stubby
RUN mkdir -p \
        /tmp/root/etc/unbound \
        /tmp/root/root/.getdns
RUN rm -rf /usr/src/stubby \
    && git clone -b v${VERSION} --depth 1 https://github.com/getdnsapi/stubby.git /usr/src/stubby
RUN cd /usr/src/stubby \
    && cmake \
       -DENABLE_SYSTEMD=OFF \
       .
RUN cd /usr/src/stubby \
    && make -j"$(nproc)" \
    && make install DESTDIR=/tmp/root
RUN unbound-anchor -v -a "/tmp/root/etc/unbound/getdns-root.key" || true \
    ldconfig /
# copy example conf
RUN cp /usr/src/stubby/stubby.yml.example /tmp/root/etc/stubby/stubby.yml \
    && rm -rf /tmp/root/usr/local/share /tmp/root/usr/local/include
# download trust anchors
RUN curl -fSsL https://data.iana.org/root-anchors/root-anchors.xml \
         -o /tmp/root/root/.getdns/root-anchors.xml


# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="$TARGETPLATFORM" \
      url="https://dnsprivacy.org/wiki/display/DP/DNS+Privacy+Daemon+-+Stubby" \
      description="Stubby is the name given to a mode of using getdns which enables \
                   it to act as a local DNS Privacy stub resolver (using DNS-over-TLS)."

# Environment
ENV TZ Asia/Tokyo

# Publish port DNS over UDP
EXPOSE 53/UDP 53/TCP

# service running
STOPSIGNAL SIGTERM

# select ENTRYPOINT
WORKDIR /etc/stubby
CMD ["/usr/local/bin/stubby"]

COPY --from=build /tmp/root/ /
RUN ldconfig /

