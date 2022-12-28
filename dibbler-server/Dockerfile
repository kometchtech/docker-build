# syntax = docker/dockerfile:experimental
FROM arm64v8/alpine:latest AS build

# Environment
ARG VERSION="master"
#ENV VERSION RELEASE1.0.1
ARG BUILD_BASE="build-base binutils clang llvm lld make gawk autoconf automake libtool curl "
ARG BUILD_PKGS="${BUILD_BASE} ca-certificates linux-headers git  "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -D_FORTIFY_SOURCE=2 -fPIE "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "
ENV CC="clang"
ENV CXX="clang++"
ENV AR="llvm-ar"
ENV NM="llvm-nm"
ENV RANLIB="llvm-ranlib"
ENV LD="ld.lld"

# compile and install
RUN mkdir -p /usr/src /tmp/root/etc/dibbler/ \
    && apk add --update --no-cache ${BUILD_PKGS}
RUN git clone -b ${VERSION} --depth=1 https://github.com/tomaszmrugalski/dibbler.git /usr/src
RUN cd /usr/src \
    && autoreconf -ifv \
    && ./configure \
      CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" \
      --sysconfdir=/etc/dibbler \
      --disable-static \
    && make -j "$(nproc)" install DESTDIR=/tmp/root
RUN ldconfig /
RUN cp /tmp/root/usr/local/share/doc/dibbler/examples/server.conf /tmp/root/etc/dibbler/server.conf \
    && rm -rf /tmp/root/usr/local/share/man/* /tmp/root/usr/local/share/doc/*


# runtime container build
FROM arm64v8/alpine:latest AS runtime

# install runtime dependencies
ARG RUN_PKGS="libstdc++ libgcc tzdata"

RUN apk add --update --no-cache ${RUN_PKGS} \
    && rm -rf /var/cache/apk/* /usr/local/share/man/* \
    && mkdir -p /var/lib/dibbler

# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      description="Portable DHCPv6 implementation" \
      url="http://klub.com.pl/dhcpv6/"

# Environment
ENV TZ Asia/Tokyo

# publish port TCP and UDP
EXPOSE 547/TCP 547/UDP

# service running
STOPSIGNAL SIGTERM

# volume
WORKDIR /etc/dibbler
#VOLUME ["/etc/dibbler", "/var/lib/dibbler"]

# Select entrypoint
CMD ["/usr/local/sbin/dibbler-server", "run"]

# Fetch binary images
COPY --from=build /tmp/root /
RUN ldconfig /
