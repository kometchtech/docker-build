# syntax = docker/dockerfile:experimental
FROM --platform=$TARGETPLATFORM debian:stable AS build

# Environment
ARG VERSION="9.15.0"
ARG BUILD_BASE="build-essential gawk autoconf automake libtool xz-utils curl "
ARG BUILD_PKGS="${BUILD_BASE} libssl-dev libcap-dev libperl-dev  libedit-dev libreadline-dev libncurses-dev zlib1g-dev \
                libxml2-dev libjson-c-dev libbsd-dev libuv1-dev libstdc++-10-pic libc6 libnghttp2-dev "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer "
ARG CXXFLAGS="${CFLAGS} -std=c++11 -stdlib=libc++ -nostdinc++ "
ARG LDFLAGS="-Wl,-O2 -Wl,-z,relro -Wl,-z,now -Wl,--as-needed "

# dev package install
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install ${BUILD_PKGS}

## build
RUN mkdir -p /tmp/build
RUN curl -fsSL "https://downloads.isc.org/isc/bind9/${VERSION}/bind-${VERSION}.tar.xz" \
         -o bind9.tar.xz
RUN tar xf bind9.tar.xz --strip-components=1 -C /tmp/build \
    && rm -f bind9.tar.xz
RUN cd /tmp/build \
#    && ./autogen.sh \
    && ./configure \
        --prefix=/usr/local \
        --sysconfdir=/etc/named \
        --localstatedir=/var \
        --with-libxml2 \
#       --with-dlopen=yes \
        --with-libtool \
        --disable-static \
        --with-openssl \
        --with-tuning=large \
        --enable-largefile \
        --enable-backtrace \
        --enable-symtable \
        --with-dlz-filesystem \
        --with-dlz-stub \
        --enable-fixed-rrset \
        --with-zlib \
        --with-readline \
        --without-python \
        CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
    && make -j"$(nproc)" \
    && make install DESTDIR=/tmp/root
RUN ldconfig /
# Delete unnecessary directory
RUN mkdir -p /tmp/root/var/cache/named \
    && rm -rf /tmp/root/var/run /tmp/root/usr/local/share/man/*
# download named.root 
RUN curl -fsSL "https://www.internic.net/domain/named.root" -o /tmp/root/var/cache/named/named.ca


# Intermediate container with runtime dependencies
FROM --platform=$TARGETPLATFORM debian:stable-slim AS runtime

# Install runtime dependencies
ARG RUN_PKGS="libprotobuf-c1 tzdata zlib1g openssl libcap2 libjson-c5 libxml2 libuv1 libnghttp2-14 "
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
      arch="$TARGETPLATFORM" \
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
ENTRYPOINT ["/usr/local/sbin/entrypoint.sh"]
CMD ["/usr/local/sbin/named", "-c", "/etc/named/named.conf", "-g", "-u", "_named"]

