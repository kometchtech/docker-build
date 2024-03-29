# Intermediate container for Knot DNS build (not persistent)
FROM --platform=$TARGETPLATFORM debian:stable AS knot-dns-build

# Environment
ENV DEBIAN_FRONTEND noninteractive
ARG KNOT_DNS_VERSION="3.1.8"
# Build dependencies
ENV KNOT_DNS_BUILD_DEPS="git-core build-essential libtool autoconf pkg-config \
						libgnutls28-dev	libprotobuf-dev libprotobuf-c-dev libfstrm-dev meson"
ENV KNOT_RESOLVER_BUILD_DEPS="build-essential pkg-config bsdmainutils liblmdb-dev \
						libluajit-5.1-dev libuv1-dev libprotobuf-dev libprotobuf-c-dev \
						libfstrm-dev luajit lua-http libssl-dev libnghttp2-dev protobuf-c-compiler"
ENV BUILDENV_DEPS="${KNOT_DNS_BUILD_DEPS} ${KNOT_RESOLVER_BUILD_DEPS}"
ARG BUILDENV_DEPS="${KNOT_DNS_BUILD_DEPS} ${KNOT_RESOLVER_BUILD_DEPS}"
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIC -fPIE -D_GNU_SOURCE "
ARG CXXFLAGS="${CFLAGS} "
ARG LDFLAGS="-Wl,--export-dynamic -Wl,-z,relro -Wl,-z,now "

# Install dependencies and sources
#RUN echo "deb http://deb.debian.org/debian stretch-backports main" > /etc/apt/sources.list.d/backports.list
RUN apt-get update -qq \
    && apt-get -y -qqq install ${BUILDENV_DEPS} 
#    && apt-get -y -qqq install -t stretch-backports meson

# Install Knot DNS from sources
RUN git clone -b v${KNOT_DNS_VERSION} --depth=1 https://gitlab.labs.nic.cz/knot/knot-dns.git /tmp/knot-dns
RUN cd /tmp/knot-dns \
    && autoreconf -if \
    && ./configure \
     --disable-fastparser \
     --disable-documentation \
     --disable-daemon \
     --disable-utilities \
     --with-lmdb=no \
    && make -j"$(nproc)" install
RUN ldconfig /

# Copy libknot, libdnssec, libzscanner to runtime
RUN mkdir -p /tmp/root/usr/local/include /tmp/root/usr/local/lib /tmp/root/usr/local/lib/pkgconfig
RUN cp -r /usr/local/include/libknot /usr/local/include/libdnssec /usr/local/include/libzscanner /tmp/root/usr/local/include
RUN cp -r /usr/local/lib/libknot* /usr/local/lib/libdnssec* /usr/local/lib/libzscanner* /tmp/root/usr/local/lib
RUN cp -r /usr/local/lib/pkgconfig/libknot.pc /usr/local/lib/pkgconfig/libdnssec.pc /usr/local/lib/pkgconfig/libzscanner.pc /tmp/root/usr/local/lib/pkgconfig


# Intermediate container with runtime dependencies
FROM --platform=$TARGETPLATFORM debian:stable-slim AS runtime

# Install runtime dependencies
ENV KNOT_DNS_RUNTIME_DEPS="libgnutls30"
ENV KNOT_RESOLVER_RUNTIME_DEPS="liblmdb0 luajit libluajit-5.1-2 libuv1 lua-http libnghttp2-14 tini libpsl5 "
ENV KNOT_RESOLVER_RUNTIME_DEPS_HTTP="lua-http lua-mmdb "
ENV KNOT_RESOLVER_RUNTIME_DEPS_EXTRA="lua-cqueues "
ENV KNOT_RESOLVER_RUNTIME_DEPS_DNSTAP="libfstrm0 libprotobuf-c1 "
ENV KNOT_RESOLVER_RUNTIME_DEPS_SSL="ca-certificates "
ENV RUNTIME_DEPS="${KNOT_DNS_RUNTIME_DEPS} ${KNOT_RESOLVER_RUNTIME_DEPS} \
    ${KNOT_RESOLVER_RUNTIME_DEPS_HTTP} ${KNOT_RESOLVER_RUNTIME_DEPS_EXTRA} \
    ${KNOT_RESOLVER_RUNTIME_DEPS_SSL} ${KNOT_RESOLVER_RUNTIME_DEPS_DNSTAP} "

RUN apt-get update -qq \
    && apt-get -y -qqq install --no-install-recommends ${RUNTIME_DEPS} \
    && apt-get clean \
    && rm -rf /var/lib/apt/list/* /usr/local/share/man/* \
    && mkdir -p /var/run/knot-resolver

# Intermediate container for Knot Resolver build
FROM knot-dns-build AS build

# Build Knot Resolver
# Environmet
ARG VERSION="4.0.0"

# Knot Resolver build
RUN mkdir -p /tmp/root/etc/knot-resolver
RUN git clone -b v${VERSION} --depth=1 --recursive https://gitlab.nic.cz/knot/knot-resolver.git /tmp/knot-resolver
RUN cd /tmp/knot-resolver \
    && meson build_docker --buildtype=plain --prefix=/usr --libdir=lib -Dc_args="${CFLAGS}" \
    && DESTDIR=/tmp/root ninja -C build_docker install \
    && cp /tmp/root/usr/share/doc/knot-resolver/examples/config.docker /tmp/root/etc/knot-resolver/kresd.conf


# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="$TARGETPLATFORM" \
      description="Knot DNS team's things are modified and used." \
      url="https://www.knot-resolver.cz"

# Environment
ENV TZ Asia/Tokyo

# publish port DNS over UDP & TCP, DNS-over-TLS
EXPOSE 53/UDP 53/TCP 853/TCP

# service running
STOPSIGNAL SIGTERM

# set entrypoint
ENTRYPOINT ["tini", "--", "/usr/local/sbin/entrypoint.sh"]
CMD ["kresd", "-n", "-c", "/etc/knot-resolver/kresd.conf"]

# Fetch Knot Resolver + Knot DNS libraries from build image
COPY --from=build /tmp/root/ /
COPY ./entrypoint.sh /usr/local/sbin/entrypoint.sh
RUN chmod +x /usr/local/sbin/entrypoint.sh \
    && ldconfig /
