FROM arm64v8/alpine:latest AS build

# Environment
ENV BIND_VERSION="9_13_5_W1" 
ARG BUILD_PKGS="build-base curl automake autoconf libressl-dev libcap-dev perl-dev linux-headers \
                bsd-compat-headers libedit-dev readline-dev ncurses-dev gawk zlib-dev"
ENV CFLAGS="-O2 -fstack-protector -pthread -pipe -fomit-frame-pointer -fPIC -FORTIFY_SOURCE=2 -fPIE "
ENV LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"

# dev package install
RUN apk add --update --no-cache ${BUILD_PKGS} 
## build
RUN mkdir -p /tmp/build \
#  && curl -fSL "https://ftp.isc.org/isc/bind9/${BIND_VERSION}/bind-${BIND_VERSION}.tar.gz" -o bind9.tar.gz \
  && curl -fSL "https://github.com/isc-projects/bind9/archive/v${BIND_VERSION}.tar.gz" -o bind9.tar.gz \
  && tar xf bind9.tar.gz --strip-components=1 -C /tmp/build \
  && rm bind9.tar.gz \
  && cd /tmp/build \
  \
  && ./configure \
    --prefix=/usr/local \
    --sysconfdir=/etc/named \
    --localstatedir=/var \
    --with-libtool \
    --with-openssl \
    --with-tuning=default \
    --enable-largefile \
    --enable-shared \
    --enable-backtrace \
    --enable-symtable \
    --with-dlz-filesystem \
    --with-dlz-stub \
    --enable-fixed-rrset \
    --with-zlib \
    --with-readline \
    --without-python \
    CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
  && make -j "$(nproc)" install DESTDIR=/tmp/root \
  && ldconfig / 
# Delete unnecessary directory 
RUN mkdir -p /tmp/root/var/named \
  && rm -rf /tmp/root/var/run /tmp/root/usr/local/share/man/* \
  # download named.root 
  && curl -fSL "https://www.internic.net/domain/named.root" -o /tmp/root/var/named/named.ca


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ARG RUN_PKGS=" protobuf-c tzdata zlib libedit readline ncurses libressl libcap "
RUN apk add --update --no-cache ${RUN_PKGS} \
     && rm -rf /var/cache/apk/* /usr/local/share/man/* 
RUN adduser -DH named \
    && mkdir -p /var/named /var/run/named /etc/named 


# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      description="BIND is open source software that enables you to publish your \
      Domain Name System (DNS) information on the Internet, and to resolve DNS queries \
      for your users.  The name BIND stands for “Berkeley Internet Name Domain”, \
      because the software originated in the early 1980s at the University of \
      California at Berkeley." \
      url="https://www.isc.org/downloads/bind/"

ENV TZ Asia/Tokyo

# volume
VOLUME ["/var/named", "/var/run/named", "/etc/named"] 

# export TCP and UDP
EXPOSE 53/tcp 53/udp 953/TCP

# select entrypoint
CMD ["named", "-c", "/etc/named/named.conf", "-g", "-u", "named"]

# Fetch isc BIND libraries from build image
COPY --from=build /tmp/root/ /
COPY ./named.conf /etc/named/named.conf
RUN chown -R named:named /var/named /var/run/named /etc/named \
    && ldconfig / || true
