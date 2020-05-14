# syntax = docker/dockerfile:experimental
# Intermediate container for Knot DNS build (not persistent)
FROM debian:stable AS knot-dns-build
ARG KNOT_DNS_VERSION=2.9.4

# Build dependencies
ENV KNOT_DNS_BUILD_DEPS="git-core build-essential libtool autoconf pkg-config \
                         libgnutls28-dev libprotobuf-dev libprotobuf-c-dev libfstrm-dev"
ENV KNOT_RESOLVER_BUILD_DEPS="build-essential pkg-config bsdmainutils liblmdb-dev \
	                          libluajit-5.1-dev libuv1-dev libprotobuf-dev libprotobuf-c-dev \
	                          libfstrm-dev luajit lua-http libssl-dev"
ENV BUILDENV_DEPS="${KNOT_DNS_BUILD_DEPS} ${KNOT_RESOLVER_BUILD_DEPS}"
ENV DEBIAN_FRONTEND=noninteractive
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIE -fomit-frame-pointer -D_FORTIFY_SOURCE=2 "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now "

RUN echo "deb http://deb.debian.org/debian stretch-backports main" > /etc/apt/sources.list.d/backports.list
RUN apt-get update -qq \
	&& apt-get -y -qqq install ${BUILDENV_DEPS} \
	&& apt-get -y -qqq install -t stretch-backports meson

# Install Knot DNS from sources
RUN git clone -b v${KNOT_DNS_VERSION} --depth=1 https://gitlab.labs.nic.cz/knot/knot-dns.git /tmp/knot-dns \
	&& cd /tmp/knot-dns \
	&& autoreconf -if \
	&& ./configure \
        --disable-static \
        --disable-fastparser \
        --disable-documentation \
		--disable-daemon \
        --disable-utilities \
        --with-lmdb=no \
    && make -j"$(nproc)" install \
    && ldconfig

# Copy libknot, libdnssec, libzscanner to runtime
RUN mkdir -p /tmp/root/usr/local/include /tmp/root/usr/local/lib /tmp/root/usr/local/lib/pkgconfig \
	&& cp -rt /tmp/root/usr/local/include /usr/local/include/libknot /usr/local/include/libdnssec /usr/local/include/libzscanner \
	&& cp -rt /tmp/root/usr/local/lib /usr/local/lib/libknot* /usr/local/lib/libdnssec* /usr/local/lib/libzscanner* \
	&& cp -rt /tmp/root/usr/local/lib/pkgconfig /usr/local/lib/pkgconfig/libknot.pc /usr/local/lib/pkgconfig/libdnssec.pc /usr/local/lib/pkgconfig/libzscanner.pc


# Intermediate container with runtime dependencies
FROM debian:stable-slim AS runtime

# Install runtime dependencies
ENV KNOT_DNS_RUNTIME_DEPS="libgnutls30"
ENV KNOT_RESOLVER_RUNTIME_DEPS="liblmdb0 luajit libluajit-5.1-2 libuv1 lua-http"
ENV KNOT_RESOLVER_RUNTIME_DEPS_HTTP="lua-http lua-mmdb"
ENV KNOT_RESOLVER_RUNTIME_DEPS_EXTRA="libfstrm0 lua-cqueues"
ENV KNOT_RESOLVER_RUNTIME_DEPS_SSL="ca-certificates"
ENV RUNTIME_DEPS="${KNOT_DNS_RUNTIME_DEPS} ${KNOT_RESOLVER_RUNTIME_DEPS} ${KNOT_RESOLVER_RUNTIME_DEPS_HTTP} \
                  ${KNOT_RESOLVER_RUNTIME_DEPS_EXTRA} ${KNOT_RESOLVER_RUNTIME_DEPS_SSL}"
RUN apt-get update -qq \
	&& apt-get install -y -qqq ${RUNTIME_DEPS} \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*


# Intermediate container for Knot Resolver build
FROM knot-dns-build AS build

ARG VERSION="5.1.0"
# Get Knot Resolver code from current directory
RUN git clone -b v${VERSION} --depth=1 https://gitlab.labs.nic.cz/knot/knot-resolver.git /tmp/knot-resolver
# Build Knot Resolver
RUN cd /tmp/knot-resolver \
    && git submodule update --init --recursive \
    && meson build_docker --buildtype=plain --prefix=/usr --libdir=lib -Dc_args="${CFLAGS}" \
	&& DESTDIR=/tmp/root ninja -C build_docker install \
	&& cp /tmp/root/usr/share/doc/knot-resolver/examples/config.docker /tmp/root/etc/knot-resolver/kresd.conf


# Final container
FROM runtime
LABEL cz.knot-resolver.vendor="CZ.NIC"
LABEL maintainer="kometchtech <kometch@gmail.com>"
LABEL arch="Aarch64"
LABEL description="Knot DNS team's things are modified and used."
LABEL url="https://www.knot-resolver.cz"

# Export DNS over UDP & TCP, DNS-over-HTTPS, DNS-over-TLS, web interface
EXPOSE 53/UDP 53/TCP 443/TCP 853/TCP 8453/TCP

# Fetch Knot Resolver + Knot DNS libraries from build image
COPY --from=build /tmp/root/ /
COPY ./entrypoint.sh /usr/local/sbin/entrypoint.sh
RUN chmod +x /usr/local/sbin/entrypoint.sh \
    && ldconfig 

ENTRYPOINT ["/usr/local/sbin/entrypoint.sh"]
CMD ["kresd", "-n", "-c", "/etc/knot-resolver/kresd.conf"]
