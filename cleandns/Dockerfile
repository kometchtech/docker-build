# syntax = docker/dockerfile:experimental

## build image
FROM arm64v8/alpine:latest AS build
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer "
ARG CXXFLAGS="${CFLAGS} "
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "
ENV CC="clang"
ENV CXX="clang++"
ENV AR="llvm-ar"
ENV NM="llvm-nm"
ENV RANLIB="llvm-ranlib"
ENV LD="ld.lld"

ARG VERSION="0.4.3"

ARG BUILD_BASE="build-base binutils clang llvm lld make gawk autoconf automake libtool curl "
ARG BUILD_PKGS="${BUILD_BASE} git"
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --update ${BUILD_PKGS}
RUN mkdir -p /tmp/cleandns
RUN git clone -b ${VERSION} --depth=1 https://github.com/GangZhuo/CleanDNS.git /tmp/cleandns
RUN cd /tmp/cleandns \
    && make clean \
    && make -j
RUN ldconfig /
# chnroute v4
RUN curl 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | \
    grep ipv4 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > /tmp/cleandns/chnroute.txt
# chnroute v6
RUN curl 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | \
    grep ipv6 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, $5) }' > /tmp/cleandns/chnroute6.txt

# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest

LABEL maintainer="kometchtech <kometch@gmail.com>" \
    arch="Aarch64" \
    description="Non-polluting DNS. Forward DNS requests with ECS (edns-client-subnet) support." \
    url="https://github.com/GangZhuo/CleanDNS"

# Environment
ENV TZ Asia/Tokyo
# publish port DNS over UDP & TCP
EXPOSE 53/UDP 53/TCP
# volume
WORKDIR /etc/cleandns

# selelct entrypoint
ENTRYPOINT cleandns -c /usr/local/share/chnroute.txt,/usr/local/share/chnroute6.txt
# Fetch build image
COPY --from=build /tmp/cleandns/cleandns /usr/local/sbin/cleandns
COPY --from=build /tmp/cleandns/chnroute.txt /usr/local/share/chnroute.txt
COPY --from=build /tmp/cleandns/chnroute6.txt /usr/local/share/chnroute6.txt


