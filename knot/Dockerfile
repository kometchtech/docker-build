# syntax = docker/dockerfile:experimental
FROM --platform=$TARGETPLATFORM debian:stable AS build

# Environment
ARG VERSION="2.8.2"
# Build dependencies
ARG BUILD_BASE="build-essential autoconf automake wget libtool "
ARG KNOT_DNS_BUILD_DEPS="${BUILD_BASE} pkg-config liblmdb-dev libmaxminddb-dev liburcu-dev libfstrm-dev \
                         libprotobuf-c-dev libprotobuf-dev libedit-dev zlib1g-dev libidn2-0-dev protobuf-c-compiler libxdp-dev \
			 libmnl-dev libnghttp2-dev libngtcp2-crypto-gnutls-dev libngtcp2-dev libgnutls28-dev libbpf-dev"
#ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer "
#ARG CXXFLAGS="${CFLAGS}"
#ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "
#ENV LD="ld.lld"

# Install dependencies and sources
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qq install ${KNOT_DNS_BUILD_DEPS}

# Install Knot DNS from sources
RUN mkdir -p /tmp/root/etc/knot-dns
#RUN git clone -b v${VERSION} https://gitlab.nic.cz/knot/knot-dns.git /tmp/knot-dns
RUN wget https://secure.nic.cz/files/knot-dns/knot-${VERSION}.tar.xz -O /tmp/knot-${VERSION}.tar.xz \
    && tar Jxvf /tmp/knot-${VERSION}.tar.xz -C /tmp
RUN cd /tmp/knot-${VERSION} \
  && autoreconf -if \
  && ./configure \
      --prefix=/usr/local \
      --with-configdir=/etc/knot \
      --with-rundir=/run/knot \
      --disable-fastparser \
      --disable-documentation \
      --enable-reuseport=auto \
      --enable-recvmmsg=auto \
      --enable-systemd=no \
      --enable-quic \
      --enable-dnstap \
      --disable-static \
      CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
      && make -j $(nproc) \
      && make install DESTDIR=/tmp/root
RUN ldconfig /
RUN cp /tmp/knot-${VERSION}/samples/knot.sample.conf.in /tmp/root/etc/knot-dns/knot.sample.conf


# Intermediate container with runtime dependencies
FROM --platform=$TARGETPLATFORM debian:stable-slim AS runtime

# Install runtime dependencies
#ARG KNOT_DNS_RUNTIME_DEPS="libprotobuf32 libprotobuf-c1 liblmdb0 libgnutls30 libedit2 liburcu8 \
#                           libidn2-0 tzdata libmaxminddb0 tini "
ARG KNOT_DNS_RUNTIME_DEPS="libbpf1 libedit2 libfstrm0 libgnutls30 libidn2-0 liblmdb0 libmaxminddb0 tini \
    			   libmnl0 libnghttp2-14 libngtcp2-crypto-gnutls2 libngtcp2-9 libprotobuf-c1 liburcu8 libxdp1"

RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && apt-get -y -qq install --no-install-recommends ${KNOT_DNS_RUNTIME_DEPS} \
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

# Fetch Knot DNS from build image
COPY --from=build /tmp/root/ /

# select entrypoint
ADD entrypoint.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/entrypoint.sh
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/sbin/entrypoint.sh"]

RUN ldconfig /

WORKDIR /etc/knot-dns
