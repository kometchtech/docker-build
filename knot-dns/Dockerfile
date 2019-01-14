FROM arm64v8/alpine:latest AS build

# Environment
ENV KNOT_DNS_VERSION 2.7.5
# Build dependencies
ARG KNOT_DNS_BUILD_DEPS="build-base clang automake autoconf libtool pkgconfig userspace-rcu-dev \
                        gnutls curl gawk git bsd-compat-headers gnutls-dev lmdb-dev libmaxminddb-dev \
                        musl-utils protobuf-c-dev protobuf-dev libedit-dev libidn-dev lld "
ARG BUILDENV_DEPS="${KNOT_DNS_BUILD_DEPS} "
#ARG CFLAGS="-O2 -fstack-protector -pthread -heap-arrays -pipe -fomit-frame-pointer -fPIC -FORTIFY_SOURCE=2 \
#            -fPIE -ftree-vectorize -ftree-slp-vectorize "
ARG CFLAGS="-O4 -pthread -pipe -fPIC -fPIC -FORTIFY_SOURCE=2 -fPIE "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,--as-needed -Wl,-z,relro -Wl,-z,now -fuse-ld=lld "
ENV CC=clang
ENV CXX=clang++

# Install dependencies and sources
RUN apk add --update --no-cache ${BUILDENV_DEPS}
# Install Knot DNS from sources
RUN mkdir -p /tmp/knot-dns/ /tmp/root/etc/knot-dns
RUN git clone -b v${KNOT_DNS_VERSION} --depth 1 https://github.com/CZ-NIC/knot.git /tmp/knot-dns \
  && cd /tmp/knot-dns \
  && autoreconf -if \
  && ./configure \
      --prefix=/ \
      --with-configdir=/etc/knot \
      --with-rundir=/run/knot \
      --enable-fastparser \
      --disable-documentation \
      --enable-reuseport=auto \
      --enable-recvmmsg=auto \
      --enable-systemd=no \
      CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
      && make -j "$(nproc)" install DESTDIR=/tmp/root 
RUN cp /tmp/knot-dns/samples/knot.sample.conf.in /tmp/root/etc/knot-dns/knot.sample.conf


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ARG KNOT_DNS_RUNTIME_DEPS="userspace-rcu lmdb gnutls libedit libidn tzdata libmaxminddb "

RUN apk add --update --no-cache ${KNOT_DNS_RUNTIME_DEPS} \
    && rm -rf /var/cache/apk/* /usr/local/share/man/* 


# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      description="Knot DNS team's things are modified and used." \
      url="https://www.knot-dns.cz/"

ENV TZ Asia/Tokyo 

# Export DNS over UDP & TCP, DNS-over-TLS
EXPOSE 53/UDP 53/TCP 853/TCP

# voulme
VOLUME ["/var/lib/knot/zones/timers", "/etc/knot-dns"]

# select entrypoint
ADD entrypoint.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/entrypoint.sh
CMD ["/usr/local/sbin/entrypoint.sh"]

# Fetch Knot DNS from build image
COPY --from=build /tmp/root/ /
RUN ldconfig / || true

