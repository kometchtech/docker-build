# syntax = docker/dockerfile:experimental

FROM arm64v8/alpine:latest AS gnutls-build

ARG MAJOR_VERSION="3.6"
ARG GNUTLS_VERSION="${MAJOR_VERSION}.12"
ARG BUILD_BASE="build-base binutils lld make gawk autoconf automake libtool curl "
ARG BUILD_PKGS="${BUILD_BASE} openssl-dev gmp-dev libgmpxx libtasn1-dev p11-kit-dev libidn2-dev \
				zlib-dev unbound-dev unbound-libs libunistring-dev libc6-compat libgcc nettle-dev "
ENV LD="ld.lld"

# build dependencies install
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache --update ${BUILD_PKGS}
RUN mkdir -p /usr/src /tmp/root
# app build
RUN curl -fSsL https://www.gnupg.org/ftp/gcrypt/gnutls/v${MAJOR_VERSION}/gnutls-${GNUTLS_VERSION}.tar.xz \
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
 #      --disable-cxx \
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
RUN cd /tmp/root/usr/local/lib \
    && strip -s \
            libgnutls-dane.so.0.4.1 \
            libgnutls-openssl.so.27.0.2 \
            libgnutls.so.30.26.2

FROM arm64v8/alpine:latest AS getdns-build
ARG GETDNS_VERSION="1.6.0"
ARG BUILD_BASE="build-base binutils clang lld llvm make gawk autoconf automake libtool curl cmake "
ARG BUILD_PKGS="${BUILD_BASE} git yaml-dev linux-headers libuv-dev libev-dev check-dev unbound-dev \
                libevent-dev libidn2-dev libtasn1-dev libc6-compat libgcc nettle-dev openssl-dev "
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

# build dependencies install
COPY --from=gnutls-build /tmp/root/usr/local/ /usr/local/
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache --update ${BUILD_PKGS}
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
       -DCMAKE_BUILD_TYPE=release \
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
       -DGNUTLS_INCLUDE_DIR=/usr/local/include \
       -DCMAKE_C_FLAGS=${CFLAGS} \
#       -DCMAKE_MODULE_LINKER_FLAGS=${LDFLAGS} \
#       -DCMAKE_SHARED_LINKER_FLAGS=${LDFLAGS} \
       -DCMAKE_INSTALL_PREFIX=/usr/local \
       ..
RUN cd /usr/src/build \
    && make -j"$(nproc)" \
    && make install
RUN ldconfig /
RUN cd /usr/local/lib \
    && strip -s libgetdns.so.10.1.3
# Copy libgetdns, libgetdns_ext_ev, libgetdns_ext_uv
RUN cp -r /usr/local/lib/* /tmp/root/usr/local/lib/ \
    && cp -r /usr/local/include/* /tmp/root/usr/local/include/ \
    && rm -rf /tmp/root/var/run /tmp/root/usr/local/share/man/*


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
COPY --from=gnutls-build /tmp/root/usr/local/lib /usr/local/lib
ENV RUN_PKGS "tzdata yaml libuv libev libevent unbound-libs tini libidn2 libtasn1 nettle openssl "
RUN apk add --update --no-cache ${RUN_PKGS} \
    && rm -rf /var/cache/apk/* /usr/local/share/* \
    && mkdir -p /var/cache/stubby


# build stubby
FROM getdns-build AS build

ARG VERSION="0.2.6"
ARG BUILD_BASE="build-base binutils clang llvm make gawk autoconf automake libtool curl "
ARG BUILD_PKGS="${BUILD_BASE} yaml unbound git "
#ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer -fuse-ld=lld "
#ARG CXXFLAGS="${CFLAGS}"
#ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "
#ENV CC="clang" \
#    CXX="clang++" \
#    AR="llvm-ar" \
#    NM="llvm-nm" \
#    RANLIB="llvm-ranlib" \
#    LD="ld.lld" \
#    STRIP="llvm-strip"

RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache --update ${BUILD_PKGS}
# build stubby
RUN mkdir -p \
        /tmp/root/etc/unbound \
        /tmp/root/root/.getdns
RUN cd /usr/src/stubby \
    && cmake \
       -DCMAKE_BUILD_TYPE=release \
       -DENABLE_SYSTEMD=OFF \
       -DGETDNS_LIBRARIES=/tmp/root/usr/local/lib/ \
       -DGETDNS_INCLUDE_DIR=/tmp/root/usr/local/include \
       .
RUN cd /usr/src/stubby \
    && make -j"$(nproc)" \
    && make install DESTDIR=/tmp/root
# reduse size
RUN strip -ps /tmp/root/usr/local/bin/stubby \
              /tmp/root/usr/local/lib/libgetdns.so.10.1.3 \
              /tmp/root/usr/local/lib/libgnutls.so.30.26.2 \
    && unbound-anchor -v -a "/tmp/root/etc/unbound/getdns-root.key" || true
# copy example conf
RUN cp /usr/src/stubby/stubby.yml.example /tmp/root/etc/stubby/stubby.yml \
    && rm -rf /tmp/root/usr/local/share /tmp/root/usr/local/include
# download trust anchors
RUN curl -fSsL https://data.iana.org/root-anchors/root-anchors.xml \
         -o /tmp/root/root/.getdns/root-anchors.xml


# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
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
COPY ["entrypoint.sh", "/usr/bin/"]
ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/entrypoint.sh"]
CMD ["/usr/local/bin/stubby", "-C", "/etc/stubby/stubby.yml"]

COPY --from=build /tmp/root/ /
RUN ldconfig /

