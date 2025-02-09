# syntax = docker/dockerfile:experimental
FROM --platform=$TARGETPLATFORM debian:stable-slim AS build

# Environment
ARG VERSION
ARG BUILD_PKGS="build-essential gawk autoconf automake libtool xz-utils curl clang \
                libssl-dev libcap-dev libperl-dev libedit-dev libreadline-dev libncurses-dev zlib1g-dev libjemalloc-dev \
                libxml2-dev libjson-c-dev libbsd-dev libuv1-dev libstdc++-11-pic libc6 libnghttp2-dev liburcu-dev ca-certificates"
#ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer -fuse-ld=mold"
#ARG CXXFLAGS="${CFLAGS} -std=c++11 -stdlib=libc++ -nostdinc++"
#ARG LDFLAGS="-Wl,-O2 -Wl,-z,relro -Wl,-z,now -Wl,--as-needed"
ARG CFLAGS="-Os -fomit-frame-pointer "
ARG CXXFLAGS="${CFLAGS} "
ARG LDFLAGS="-Wl,--as-needed -rdynamic "
ARG CC=clang
ARG CXX=clang++

# Install build dependencies and build BIND
RUN set -ex \
    && DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get install -y --no-install-recommends ${BUILD_PKGS} \
    && mkdir -p /tmp/build \
    && curl -fsSL "https://downloads.isc.org/isc/bind9/${VERSION}/bind-${VERSION}.tar.xz" | tar xJ --strip-components=1 -C /tmp/build \
    && cd /tmp/build \
    && ./configure \
        --prefix=/usr/local \
        --sysconfdir=/etc/named \
        --localstatedir=/var \
        --with-libxml2 \
        --disable-static \
        --enable-largefile \
        --enable-fixed-rrset \
        --with-zlib \
        --with-readline \
        CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
    && make -j1 \
    && make install DESTDIR=/tmp/root \
    && ldconfig / \
    && mkdir -p /tmp/root/var/cache/named \
    && rm -rf /tmp/root/var/run /tmp/root/usr/local/share/man/* \
    && curl -fsSL "https://www.internic.net/domain/named.root" -o /tmp/root/var/cache/named/named.ca \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*


# Intermediate container with runtime dependencies
FROM --platform=$TARGETPLATFORM debian:stable-slim AS runtime

# Install runtime dependencies
ARG RUN_PKGS="libprotobuf-c1 tzdata zlib1g openssl libcap2 libjson-c5 libxml2 libuv1 libnghttp2-14 liburcu8 tini libjemalloc2 "
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install --no-install-recommends ${RUN_PKGS} \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /usr/local/share/man/* /var/lib/apt/lists/* \
# add user and make dir
	&& groupadd _named \
	&& useradd -g _named -s /dev/null -d /etc _named \
    && mkdir -p /etc/named /var/cache/named /var/run/named /var/cache/named/dynamic

# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      description="BIND is open source software that enables you to publish your \
                  Domain Name System (DNS) information on the Internet, and to \
                  resolve DNS queries for your users.  The name BIND stands for \
                  Berkeley Internet Name Domain”, because the software originated \
                  in the early 1980s at the University of California at Berkeley." \
      url="https://www.isc.org/downloads/bind/"

# Environment
ENV TZ Asia/Tokyo

# publish port TCP and UDP
EXPOSE 53/tcp 53/udp 953/TCP

# service running
STOPSIGNAL SIGTERM

# Fetch isc BIND libraries from build image
COPY --from=build /tmp/root/ /
COPY ./named.conf /etc/named/named.conf
COPY ./local.zone /var/cache/named/pri/local.zone
COPY ./local.rev /var/cache/named/pri/local.rev
RUN chown -R _named:_named /var/cache/named /etc/named /var/run/named /var/cache/named/dynamic \
    && ldconfig /

# Application execution related information
COPY ./entrypoint.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/entrypoint.sh

# select entrypoint
WORKDIR /etc/named
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/sbin/entrypoint.sh"]
CMD ["/usr/local/sbin/named", "-c", "/etc/named/named.conf", "-g", "-u", "_named"]
