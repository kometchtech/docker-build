# syntax = docker/dockerfile:experimental
FROM --platform=$TARGETPLATFORM debian:stable AS build

# Environment
ARG VERSION="2.8.2"
# Build dependencies
ARG BUILD_BASE="build-essential lld gawk autoconf automake libtool curl git "
ARG KNOT_DNS_BUILD_DEPS="${BUILD_BASE} pkg-config gnutls-dev liblmdb-dev libmaxminddb-dev liburcu-dev \
                         libprotobuf-c-dev libprotobuf-dev libedit-dev zlib1g-dev libidn2-dev "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "
ENV LD="ld.lld"

# Install dependencies and sources
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install ${KNOT_DNS_BUILD_DEPS}

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
FROM --platform=$TARGETPLATFORM debian:stable-slim AS runtime

# Install runtime dependencies
ARG KNOT_DNS_RUNTIME_DEPS="libprotobuf23 libprotobuf-c1 liblmdb0 libgnutls30 libedit2 liburcu6 \
                           libidn2-0 tzdata libmaxminddb0 tini "

RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qqq install --no-install-recommends ${KNOT_DNS_RUNTIME_DEPS} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /usr/local/share/man/*


# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="$TARGETPLATFORM" \
      description="Knot DNS team's things are modified and used." \
      url="https://www.knot-dns.cz/"

# Environment
ENV TZ Asia/Tokyo

# publish port DNS over UDP & TCP, DNS-over-TLS
EXPOSE 53/UDP 53/TCP 853/TCP

# service running
STOPSIGNAL SIGTERM

# voulme
WORKDIR /etc/knot-dns

# select entrypoint
ADD entrypoint.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/entrypoint.sh
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/sbin/entrypoint.sh"]

# Fetch Knot DNS from build image
COPY --from=build /tmp/root/ /
RUN ldconfig /

