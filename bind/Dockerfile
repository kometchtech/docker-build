# syntax = docker/dockerfile:experimental
FROM arm64v8/alpine:latest AS build

# Environment
ENV VERSION="9.15.0"
ARG BUILD_PKGS="build-base curl automake autoconf libressl-dev libcap-dev perl-dev linux-headers gawk \
                bsd-compat-headers libedit-dev readline-dev ncurses-dev zlib-dev libxml2-dev json-c-dev libtool "
ARG CFLAGS="-std=gnu99 -O2 -pthread -pipe -fPIC -fPIC -D_GNU_SOURCE -fPIE "
ARG CXXFLAGS="${CFLAGS} "
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "

# dev package install
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --update ${BUILD_PKGS}
## build
RUN mkdir -p /tmp/build
RUN curl -fsSL "https://ftp.isc.org/isc/bind9/${VERSION}/bind-${VERSION}.tar.gz" -o bind9.tar.gz
RUN tar xf bind9.tar.gz --strip-components=1 -C /tmp/build \
    && rm bind9.tar.gz
RUN cd /tmp/build \
  && ./autogen.sh \
  && ./configure \
    --prefix=/usr/local \
    --sysconfdir=/etc/named \
    --localstatedir=/var \
    --with-libtool \
    --disable-static \
    --with-openssl \
    --with-tuning=default \
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
  && make -j"$(nproc)" install DESTDIR=/tmp/root
RUN ldconfig /
# Delete unnecessary directory
RUN mkdir -p /tmp/root/var/cache/named \
  && rm -rf /tmp/root/var/run /tmp/root/usr/local/share/man/*
# download named.root 
RUN curl -fsSL "https://www.internic.net/domain/named.root" -o /tmp/root/var/cache/named/named.ca


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ARG RUN_PKGS="protobuf-c tzdata zlib libressl2.7-libcrypto libcap json-c libxml2 "
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --update --no-cache ${RUN_PKGS} \
    && rm -rf /var/cache/apk/* /usr/local/share/man/* \
# add user and make dir
    && adduser -DH named \
    && mkdir -p /etc/named /var/cache/named /var/run/named


# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
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

# select entrypoint
WORKDIR /etc/named
CMD ["named", "-c", "/etc/named/named.conf", "-g", "-u", "named"]

# Fetch isc BIND libraries from build image
COPY --from=build /tmp/root/ /
COPY ./named.conf /etc/named/named.conf
RUN chown -R named:named /var/cache/named /etc/named /var/run/named \
    && ldconfig /