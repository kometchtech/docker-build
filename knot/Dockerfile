# syntax = docker/dockerfile:experimental
FROM arm64v8/alpine:latest AS build

# Environment
ARG VERSION="2.8.2"
# Build dependencies
ARG BUILD_BASE="build-base binutils clang llvm lld make gawk autoconf automake libtool curl "
ARG KNOT_DNS_BUILD_DEPS="${BUILD_BASE} pkgconfig userspace-rcu-dev \
                        git bsd-compat-headers gnutls-dev lmdb-dev libmaxminddb-dev \
                        musl-utils protobuf-c-dev protobuf-dev libedit-dev libidn2-dev "
ARG BUILDENV_DEPS="${KNOT_DNS_BUILD_DEPS} "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer -D_FORTIFY_SOURCE=2 "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "
ENV CC="clang" \
    CXX="clang++" \
    AR="llvm-ar" \
    NM="llvm-nm" \
    RANLIB="llvm-ranlib" \
    LD="ld.lld" \
    STRIP="llvm-strip"

# Install dependencies and sources
RUN --mount=type=cache,target=/var/cache/apk \
  apk add --update ${BUILDENV_DEPS}
# Install Knot DNS from sources
RUN mkdir -p /tmp/knot-dns/ /tmp/root/etc/knot-dns
RUN git clone -b v${VERSION} --depth=1 https://github.com/CZ-NIC/knot.git /tmp/knot-dns
RUN cd /tmp/knot-dns \
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
      && make -j "$(nproc)" \
      && make install DESTDIR=/tmp/root
RUN ldconfig /
RUN cp /tmp/knot-dns/samples/knot.sample.conf.in /tmp/root/etc/knot-dns/knot.sample.conf


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ARG KNOT_DNS_RUNTIME_DEPS="protobuf protobuf-c userspace-rcu lmdb gnutls libedit libidn2 tzdata \
                           libmaxminddb tini "
RUN --mount=type=cache,target=/var/cache/apk \
  apk add --update --no-cache ${KNOT_DNS_RUNTIME_DEPS} \
  && rm -rf /var/cache/apk/* /usr/local/share/man/*


# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      description="Knot DNS team's things are modified and used." \
      url="https://www.knot-dns.cz/"

# Environment
ENV TZ Asia/Tokyo

# publish port DNS over UDP & TCP, DNS-over-TLS
EXPOSE 53/UDP 53/TCP 853/TCP

# service running
STOPSIGNAL SIGTERM

# voulme
#VOLUME ["/var/lib/knot/zones/timers", "/etc/knot-dns"]
WORKDIR /etc/knot-dns

# select entrypoint
ADD entrypoint.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/entrypoint.sh
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/sbin/entrypoint.sh"]

# Fetch Knot DNS from build image
COPY --from=build /tmp/root/ /
RUN ldconfig /

