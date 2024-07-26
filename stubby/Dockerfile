# syntax = docker/dockerfile:experimental

FROM --platform=$TARGETPLATFORM debian:stable AS gnutls-build

ARG MAJOR_VERSION="3.8"
ARG GNUTLS_VERSION="${MAJOR_VERSION}.5"
ARG BUILD_BASE="build-essential pkg-config autoconf automake libtool xz-utils curl gettext mold "
ARG BUILD_PKGS="${BUILD_BASE} libssl-dev libgmp-dev libgmpxx4ldbl libtasn1-dev libp11-kit-dev libidn2-dev \
		zlib1g-dev libunbound-dev libunbound8 libunistring-dev libc6 libnettle8 nettle-dev bison python3-minimal "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer -fuse-ld=mold "
ARG CXXFLAGS="${CFLAGS} "
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "

# build dependencies install
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install ${BUILD_PKGS}

RUN mkdir -p /usr/src /tmp/root
# app build
RUN curl -fSsL http://www.ring.gr.jp/pub/net/gnupg/gnutls/v${MAJOR_VERSION}/gnutls-${GNUTLS_VERSION}.tar.xz \
    -o gnutls.tar.xz \
    && tar xf gnutls.tar.xz --strip-components=1 -C /usr/src \
    && rm -f gnutls.tar.xz
RUN cd /usr/src \
    && ./configure \
       --disable-doc \
       --disable-tests \
       --enable-shared \
#       --disable-tools \
#       --disable-guile \
#       --disable-srp-authentication \
#       --disable-psk-authentication \
#       --disable-anon-authentication \
       --enable-openssl-compatibility \
#       --disable-dtls-srtp-support \
#       --disable-alpn-support \
#       --disable-heartbeat-support \
#       --without-p11-kit \
#       --without-tpm
       --with-default-trust-store-pkcs11="pkcs11:" 
RUN cd /usr/src \
	&& make -j"$(nproc)" \
    && make check install \
	&& make install DESTDIR=/tmp/root
RUN cd /tmp/root/usr/local/lib


FROM --platform=$TARGETPLATFORM debian:stable AS getdns-build
ARG GETDNS_VERSION="1.7.3"
ARG CMAKE_VERSION="3.29.1"
ARG BUILD_BASE="build-essential autoconf mold pkg-config gettext cmake "
ARG BUILD_PKGS="${BUILD_BASE} git wget libyaml-dev libunbound-dev libidn2.0-dev libtasn1-dev nettle-dev libssl-dev libev-dev \
		libuv1-dev libevent-dev check "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer -fuse-ld=mold "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now -fuse-ld=mold "

# build dependencies install
COPY --from=gnutls-build /tmp/root/usr/local/ /usr/local/
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install ${BUILD_PKGS}

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
RUN ldconfig / \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /usr/local/share/man/* /var/lib/apt/lists/* \
# Copy libgetdns, libgetdns_ext_ev, libgetdns_ext_uv
    && cp -r /usr/local/lib/* /tmp/root/usr/local/lib/ \
    && cp -r /usr/local/include/* /tmp/root/usr/local/include/ \
    && rm -rf /tmp/root/var/run /tmp/root/usr/local/share/man/*


# Intermediate container with runtime dependencies
FROM --platform=$TARGETPLATFORM debian:stable-slim AS runtime
# Install runtime dependencies
COPY --from=gnutls-build /tmp/root/usr/local/lib /usr/local/lib
ENV RUN_PKGS "libyaml-0-2 libuv1 libev4 libevent-2.1-7 libunbound8 tini libidn2-0 libtasn1-6 libnettle8 libssl3 ca-certificates "
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install ${RUN_PKGS} \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /usr/local/share/man/* /var/lib/apt/lists/* \
    && mkdir -p /var/cache/stubby \
    && ldconfig /


# build stubby
FROM getdns-build AS build

ARG VERSION="0.2.6"
ARG BUILD_BASE="build-essential autoconf curl "
ARG BUILD_PKGS="${BUILD_BASE} libyaml-dev unbound git libyaml-0-2 ca-certificates "
ENV CC=gcc \
    CXX=g++

RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install ${BUILD_PKGS}

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
    && ldconfig / \
# copy example conf
    && cp /usr/src/stubby/stubby.yml.example /tmp/root/etc/stubby/stubby.yml \
    && rm -rf /tmp/root/usr/local/share /tmp/root/usr/local/include \
# download trust anchors
    && curl -fSsL https://data.iana.org/root-anchors/root-anchors.xml \
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

