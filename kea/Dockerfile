# syntax = docker/dockerfile:experimental

## base image
FROM arm64v8/alpine:latest AS base-image
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer "
ARG CXXFLAGS="${CFLAGS} "
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "
ENV CC="clang" \
    CXX="clang++" \
    AR="llvm-ar" \
    NM="llvm-nm" \
    RANLIB="llvm-ranlib" \
    LD="ld.lld" \
    STRIP="llvm-strip"

ARG BUILD_BASE="build-base binutils clang llvm lld make gawk autoconf automake libtool curl "
ARG BUILD_PKGS="${BUILD_BASE}"
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --update ${BUILD_PKGS}


## log4cplus
FROM base-image AS log4cplus

# Environment
#ENV LOG4CPLUS="1.2.2"
ENV LOG4CPLUS="2.0.5"
ENV LOG4CPLUS_SOURCE="https://sourceforge.net/projects/log4cplus/files/log4cplus-stable/${LOG4CPLUS}/log4cplus-${LOG4CPLUS}.tar.bz2"

# build library
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --update ${BUILD_PKGS}
RUN mkdir -p /usr/local/src \
    && curl -fSsL "${LOG4CPLUS_SOURCE}" -o log4cplus.tar.bz2 \
    && tar xf log4cplus.tar.bz2 --strip-components=1 -C /usr/local/src \
    && rm log4cplus.tar.bz2
RUN cd /usr/local/src \
    && ./configure \
        CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
    && make -j$(nproc) \
    && make install DESTDIR=/tmp/root
RUN ldconfig /


## botan
FROM base-image AS botan

# Environment
ENV BOTAN="2.12.1"
ARG BUILD_PKGS="boost-dev bzip2-dev openssl-dev zlib-dev sqlite-dev "
ARG CFLAGS="-O2 -pthread -pipe -fomit-frame-pointer "
ARG CXXFLAGS="${CFLAGS} "
ARG CPPFLAGS="${CFLAGS} "

# build library
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --update ${BUILD_PKGS}
RUN mkdir -p /usr/local/src \
    && curl -fsSL "https://github.com/randombit/botan/archive/${BOTAN}.tar.gz" -o botan.tar.gz \
    && tar xf botan.tar.gz --strip-components=1 -C /usr/local/src \
    && rm botan.tar.gz
RUN cd /usr/local/src \
    && ./configure.py \
        --disable-static-library \
        --optimize-for-size \
        --amalgamation \
        --minimized-build \
        --without-documentation \
    && make -j"$(nproc)" install DESTDIR=/tmp/root
RUN ldconfig /


# build binary
FROM base-image AS build

# Environment
ARG VERSION="1.6.0-beta"
ARG BUILD_PKGS="boost-dev postgresql-dev mariadb-dev bison flex perl curl openssl-dev "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer "

# dev package install
COPY --from=log4cplus /tmp/root /
COPY --from=botan /tmp/root /
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --update ${BUILD_PKGS}
## build
RUN mkdir -p /tmp/build \
  && curl -fSsL "https://ftp.isc.org/isc/kea/${VERSION}/kea-${VERSION}.tar.gz" -o kea.tar.gz \
  && tar xf kea.tar.gz --strip-components=1 -C /tmp/build \
  && rm kea.tar.gz
RUN cd /tmp/build \
  && autoreconf -if \
  && ./configure \
    --prefix=/usr/local \
    --sysconfdir=/etc \
    --disable-rpath \
    --disable-static \
    --with-boost-include \
    --with-botan-config \
    --with-mysql \
    --with-pgsql \
    --with-log4cplus \
#    --disable-dependency-tracking \
    CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}"
RUN cd /tmp/build \
    && make -j"$(nproc)" \
    && make install DESTDIR=/tmp/root
RUN llvm-strip /tmp/root/usr/local/sbin/kea-dhcp4 \
        /tmp/root/usr/local/sbin/kea-dhcp6 \
        /tmp/root/usr/local/sbin/kea-dhcp-ddns \
        /tmp/root/usr/local/sbin/kea-ctrl-agent \
        /tmp/root/usr/local/sbin/kea-lfc
RUN ldconfig /
# Delete unnecessary directory
RUN rm -rf /tmp/root/var/run /tmp/root/usr/local/share/man/* /tmp/root/usr/local/include /tmp/root/usr/include \
           /tmp/root/usr/share/kea /tmp/root/usr/share/doc/kea /tmp/root/usr/local/lib/kea/hooks/*.la \
           /tmp/root/usr/local/lib/*.la


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ARG RUN_PKGS="libgcc libstdc++ boost-system mariadb-connector-c libpq tzdata procps openssl libatomic \
              tini "
COPY --from=log4cplus /tmp/root /
COPY --from=botan /tmp/root /
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --update --no-cache ${RUN_PKGS} \
    && rm -rf /var/cache/apk/* /usr/local/share/man/* \
    && mkdir -p /var/lib/kea

# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      description="Kea is an open source implementation of the Dynamic Host Configuration \
                   Protocol (DHCP) servers, developed and maintained by Internet Systems Consortium (ISC)." \
      url="https://www.isc.org/kea/"

# Environment
ENV TZ Asia/Tokyo

# publish port TCP and UDP
EXPOSE 67/UDP 547/TCP 547/UDP

# service running
STOPSIGNAL SIGTERM

# select entrypoint
WORKDIR /etc/kea
COPY ./entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]

# Fetch isc Kea libraries from build image
COPY --from=build /tmp/root/ /
RUN ldconfig /
