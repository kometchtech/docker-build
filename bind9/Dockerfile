FROM arm64v8/alpine:latest AS build

# Environment
ENV BIND_VERSION="9_13_5_W1"
ARG BUILD_PKGS="build-base git curl automake autoconf libressl-dev libcap-dev perl-dev linux-headers \
                bsd-compat-headers libedit-dev readline-dev ncurses-dev zlib-dev libxml2-dev json-c-dev libtool \
                clang-dev "
#ENV CFLAGS="-O2 -fstack-protector -pthread -pipe -fomit-frame-pointer -fPIC -FORTIFY_SOURCE=2 \
#            -fPIE -ftree-vectorize -ftree-slp-vectorize"
ARG CFLAGS="-O4 -pthread -pipe -fPIC -fPIC -FORTIFY_SOURCE=2 -fPIE "
ARG CXXFLAGS="${CFLAGS} "
ARG LDFLAGS="-Wl,-O4 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now"

# dev package install
RUN apk add --update --no-cache ${BUILD_PKGS}
## build
RUN mkdir -p /tmp/build \
  && git clone -b v${BIND_VERSION} --depth 1 https://github.com/isc-projects/bind9.git /tmp/build
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
  && make -j"$(nproc)" install DESTDIR=/tmp/root \
  && ldconfig /
# Delete unnecessary directory
RUN mkdir -p /tmp/root/var/named \
  && rm -rf /tmp/root/var/run /tmp/root/usr/local/share/man/*
# download named.root 
RUN curl -fsSL "https://www.internic.net/domain/named.root" -o /tmp/root/var/named/named.ca


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ARG RUN_PKGS="protobuf-c tzdata zlib libedit readline ncurses libressl libcap json-c libxml2 "
RUN apk add --update --no-cache ${RUN_PKGS} \
    && rm -rf /var/cache/apk/* /usr/local/share/man/* \
# add user and make dir
    && adduser -DH named \
    && mkdir -p /var/named /var/run/named /etc/named 


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
