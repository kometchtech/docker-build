# syntax = docker/dockerfile:experimental
## base image
FROM --platform=$TARGETPLATFORM debian:latest AS base-image

ARG TARGETPLATFORM
ARG BUILD_BASE="build-essential binutils lld gawk autoconf automake libtool curl "
ARG BUILD_PKGS="${BUILD_BASE}"
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer "
ARG CXXFLAGS="${CFLAGS} "
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "
ENV LD="ld.lld"

# make base image
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install ${BUILD_PKGS}

## log4cplus
FROM base-image AS log4cplus

# Environment
ENV LOG4CPLUS="2.0.8"
ENV LOG4CPLUS_SOURCE="https://sourceforge.net/projects/log4cplus/files/log4cplus-stable/${LOG4CPLUS}/log4cplus-${LOG4CPLUS}.tar.bz2"

# build library
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install ${BUILD_PKGS}
RUN mkdir -p /usr/local/src \
    && curl -fSsL ${LOG4CPLUS_SOURCE} -o log4cplus.tar.bz2 \
    && tar xf log4cplus.tar.bz2 --strip-components=1 -C /usr/local/src \
    && rm log4cplus.tar.bz2
RUN cd /usr/local/src \
    && ./configure \
        CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
    && make -j$(nproc) \
    && make install-strip DESTDIR=/tmp/root
RUN ldconfig /


## botan
FROM base-image AS botan

# Environment
ENV BOTAN="2.19.1"
ARG BUILD_PKGS="libboost-dev libboost-system-dev libbz2-dev libssl-dev zlib1g-dev libsqlite3-dev python3 "
ARG CFLAGS="-O2 -pthread -pipe -fomit-frame-pointer "
ARG CXXFLAGS="${CFLAGS} "
ARG CPPFLAGS="${CFLAGS} "

# build library
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install ${BUILD_PKGS}
RUN mkdir -p /usr/local/src \
    && curl -fsSL "https://github.com/randombit/botan/archive/${BOTAN}.tar.gz" -o botan.tar.gz \
    && tar xf botan.tar.gz --strip-components=1 -C /usr/local/src \
    && rm botan.tar.gz
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN cd /usr/local/src \
    && ./configure.py \
        --with-boost \
        --with-bzip2 \
        --with-openssl \
        --with-sqlite3 \
        --with-zlib \
        --disable-static-library \
        --optimize-for-size \
        --minimized-build \
        --enable-modules=aes,aes_armv8,aes_ni,asn1,auto_rng,base,base32,base58,base64,blowfish,bzip2,cbc,cbc_mac,chacha,chacha20poly1305,chacha_rng,chacha_simd32,checksum,cmac,compression,cpuid,crc24,crc32,ctr,curve25519,des,dev_random,dh,dsa,ec_group,ecdh,ecdsa,ecgdsa,ecies,eckcdsa,ed25519,entropy,fd_unix,getentropy,hash,hash_id,hex,hmac,hmac_drbg,locking_allocator,md5,mem_pool,numbertheory,openssl,pk_pad,pkcs11,prf_tls,prf_x942,proc_walk,psk_db,pubkey,rc4,rdrand_rng,rdseed,rfc3394,rfc6979,rmd160,rng,rsa,scrypt,sha1,sha1_armv8,sha2_32,sha2_32_armv8,sha2_32_bmi2,sha2_64,sha2_64_bmi2,simd,socket,sodium,sqlite3,stateful_rng,stream,system_rng,thread_utils,tls,tls_10,tls_cbc,uuid,x509,zlib \
        --without-documentation
RUN cd /usr/local/src \
    && make -j"$(nproc)" install DESTDIR=/tmp/root \
    && rm -f /tmp/root/usr/local/bin/botan
RUN ldconfig /


# build binary
FROM base-image AS build

# Environment
ARG VERSION="1.6.0-beta"
ARG BUILD_PKGS="libboost-dev libboost-system-dev postgresql-server-dev-13 default-libmysqlclient-dev bison flex perl curl libssl-dev "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer "
ARG CXXFLAGS="${CFLAGS} "

# dev package install
COPY --from=log4cplus /tmp/root /
COPY --from=botan /tmp/root /
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install ${BUILD_PKGS}
## build
RUN mkdir -p /tmp/build \
  && curl -fSsL "https://ftp.isc.org/isc/kea/${VERSION}/kea-${VERSION}.tar.gz" \
          -o kea.tar.gz \
  && tar xf kea.tar.gz --strip-components=1 -C /tmp/build \
  && rm -f kea.tar.gz
RUN cd /tmp/build \
  && autoreconf -if \
  && ./configure \
        --prefix=/usr/local \
        --sysconfdir=/etc \
        --disable-rpath \
        --disable-static \
        --with-boost-include \
        --with-botan-config \
        --with-openssl \
        --with-mysql \
        --with-pgsql \
#        --with-cql \
        --with-log4cplus \
        CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}"
RUN cd /tmp/build \
    && make -j"$(nproc)" \
    && make install DESTDIR=/tmp/root
RUN ldconfig /
# Delete unnecessary directory
RUN rm -rf /tmp/root/var/run /tmp/root/usr/local/share/man/* /tmp/root/usr/local/include /tmp/root/usr/include \
           /tmp/root/usr/share/kea /tmp/root/usr/share/doc/kea /tmp/root/usr/local/lib/kea/hooks/*.la \
           /tmp/root/usr/local/lib/*.la /tmp/root/usr/local/include/*


# Intermediate container with runtime dependencies
FROM --platform=$TARGETPLATFORM debian:stable-slim AS runtime

# Install runtime dependencies
ARG RUN_PKGS="gcc-10-base libboost-system1.74.0 libpq5 tzdata procps libatomic1 libsqlite3-0 libbz2-1.0 libmariadb3 tini "
COPY --from=log4cplus /tmp/root /
COPY --from=botan /tmp/root /
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install ${RUN_PKGS} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /usr/local/share/man/* \
    && mkdir -p /var/lib/kea

# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="$TARGETPLATFORM" \
      description="Kea is an open source implementation of the Dynamic Host Configuration \
                   Protocol (DHCP) servers, developed and maintained by Internet Systems Consortium (ISC)." \
      url="https://www.isc.org/kea/"

# Environment
ENV TZ Asia/Tokyo

# publish port TCP and UDP
EXPOSE 67/UDP 547/TCP 547/UDP 8080

# service running
STOPSIGNAL SIGTERM

# select entrypoint
WORKDIR /etc/kea
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["/usr/local/bin/entrypoint.sh"]

COPY ./entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Fetch isc Kea libraries from build image
COPY --from=build /tmp/root/ /
RUN ldconfig /
