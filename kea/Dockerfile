# syntax = docker/dockerfile:experimental
## log4cplus
FROM arm64v8/alpine:latest AS log4cplus

# Environment
ENV LOG4CPLUS="1.2.2"
ARG BUILD_BASE="build-base binutils-gold clang make gawk autoconf automake libtool curl "
ARG BUILD_PKGS="${BUILD_BASE}"
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE "
ARG CXXFLAGS="${CFLAGS} "
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "
ENV LOG4CPLUS_SOURCE="https://sourceforge.net/projects/log4cplus/files/log4cplus-stable/${LOG4CPLUS}/log4cplus-${LOG4CPLUS}.tar.bz2"
ARG CC="clang"
ARG CXX="clang++"

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
FROM arm64v8/alpine:latest AS botan

# Environment
ENV BOTAN="2.10.0"
ARG BUILD_BASE="build-base binutils-gold clang make gawk autoconf automake libtool curl "
ARG BUILD_PKGS="${BUILD_BASE} python boost-dev bzip2-dev libressl-dev zlib-dev sqlite-dev "
ARG CC="clang"
ARG CXX="clang++"

# build library
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --update ${BUILD_PKGS}
RUN mkdir -p /usr/local/src \
    && curl -fsSL "https://botan.randombit.net/releases/Botan-${BOTAN}.tgz" -o botan.tar.gz \
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
FROM arm64v8/alpine:latest AS build

# Environment
ARG VERSION="1.6.0-beta"
ARG BUILD_BASE="build-base binutils-gold clang make clang gawk autoconf automake libtool "
ARG BUILD_PKGS="${BUILD_BASE} boost-dev postgresql-dev mariadb-dev bison flex perl curl libressl-dev"
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE "
ARG CXXFLAGS="${CFLAGS} "
ARG CPPFLAGS="${CFLAGS} "
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "
ENV CC="clang "
ENV CXX="clang++ "

# dev package install
COPY --from=log4cplus /tmp/root /
COPY --from=botan /tmp/root /
#RUN echo "@comm http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --update ${BUILD_PKGS}
## build
RUN mkdir -p /tmp/build \
  && curl -fSsL "https://ftp.isc.org/isc/kea/${VERSION}/kea-${VERSION}.tar.gz" -o kea.tar.gz \
  && tar xf kea.tar.gz --strip-components=1 -C /tmp/build \
  && rm kea.tar.gz
RUN cd /tmp/build \
  && ./configure \
    --prefix=/usr \
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
RUN ldconfig /
# Delete unnecessary directory
RUN rm -rf /tmp/root/var/run /tmp/root/usr/local/share/man/* /tmp/root/usr/local/include /tmp/root/usr/include \
           /tmp/root/usr/share/kea /tmp/root/usr/share/doc/kea


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ARG RUN_PKGS="libgcc libstdc++ boost-system mariadb-connector-c libpq tzdata procps libressl"
#RUN echo "@comm http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
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

# publish port
EXPOSE 67/udp 547/udp

# service running
STOPSIGNAL SIGTERM

# select entrypoint
WORKDIR /etc/kea
COPY ./run.sh /usr/local/bin/
ENTRYPOINT ["run.sh"]

# Fetch isc Kea libraries from build image
COPY --from=build /tmp/root/ /
RUN ldconfig /
