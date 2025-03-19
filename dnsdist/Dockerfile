# syntax = docker/dockerfile:experimental
FROM --platform=$TARGETPLATFORM rust:latest AS build

# Env
ARG VERSION=2.0.0-alpha1
ARG BUILD_BASE="build-essential binutils make gawk curl clang lld cmake ninja-build python3-full python3-pip python3-venv"
ARG BUILD_PKGS="${BUILD_BASE} pkgconf libboost-dev libsodium-dev libprotobuf-c-dev libre2-dev libsnmp-dev \
               libedit-dev libssl-dev libnghttp2-dev libgnutls28-dev libxdp-dev libbpf-dev ca-certificates libfstrm-dev \
               libsystemd-dev libcap-dev libyaml-cpp-dev libcdb-dev liblmdb-dev"
ARG LUAVER=lua5.3
ARG CC=clang
ARG CXX=clang++

# H2O version
ARG H2O_VERSION=v2.2.6

# dev package install and setup Python venv with latest meson
RUN apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${BUILD_PKGS} \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends lib${LUAVER}-dev \
    && python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir 'meson>=1.3.0' 'pyyaml' \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /usr/src /tmp/root/etc/dnsdist /build /h2o

# Setup env
ENV PATH="/opt/venv/bin:$PATH"

# Install h2o (based on install_h2o.sh)
RUN cd /h2o \
    && curl -sSL "https://github.com/h2o/h2o/archive/refs/tags/${H2O_VERSION}.tar.gz" -o h2o.tar.gz \
    && tar xf h2o.tar.gz --strip-components=1 \
    && rm h2o.tar.gz \
    && cmake -DCMAKE_INSTALL_PREFIX=/opt -DWITH_MRUBY=OFF -DWITH_PICOTLS=OFF \
       -DCMAKE_C_FLAGS="-mno-outline-atomics" \
       -DWITH_BUNDLED_SSL=OFF . \
    && make -j$(nproc) \
    && make install \
    && mkdir -p /opt/lib/pkgconfig \
    && echo "prefix=/opt" > /opt/lib/pkgconfig/libh2o-evloop.pc \
    && echo "exec_prefix=\${prefix}" >> /opt/lib/pkgconfig/libh2o-evloop.pc \
    && echo "libdir=\${exec_prefix}/lib" >> /opt/lib/pkgconfig/libh2o-evloop.pc \
    && echo "includedir=\${prefix}/include" >> /opt/lib/pkgconfig/libh2o-evloop.pc \
    && echo "Name: libh2o-evloop" >> /opt/lib/pkgconfig/libh2o-evloop.pc \
    && echo "Description: H2O HTTP library" >> /opt/lib/pkgconfig/libh2o-evloop.pc \
    && echo "Version: ${H2O_VERSION#v}" >> /opt/lib/pkgconfig/libh2o-evloop.pc \
    && echo "Libs: -L\${libdir} -lh2o-evloop" >> /opt/lib/pkgconfig/libh2o-evloop.pc \
    && echo "Cflags: -I\${includedir}" >> /opt/lib/pkgconfig/libh2o-evloop.pc \
    && ln -sf /opt/lib/libh2o-evloop.* /usr/lib/ \
    && echo "/opt/lib" > /etc/ld.so.conf.d/h2o.conf

## download source
RUN curl -fsSL "https://downloads.powerdns.com/releases/dnsdist-${VERSION}.tar.xz" -o dnsdist.tar.xz \
    && tar xf dnsdist.tar.xz --strip-components=1 -C /usr/src \
    && rm dnsdist.tar.xz \
    && groupadd _dnsdist \
    && useradd -g _dnsdist -s /dev/null -d /etc _dnsdist

# Apply patches for compatibility
RUN if grep -q "license_files" /usr/src/meson.build; then \
      sed -i 's/license_files: \[[^]]*\]//' /usr/src/meson.build; \
    fi \
    && if [ -f /usr/src/meson/quiche/meson.build ]; then \
      sed -i 's/bool(opt)/opt.enabled()/' /usr/src/meson/quiche/meson.build; \
    fi

# Build with meson from venv
RUN cd /usr/src \
    && BUILDDIR=$(mktemp -d) \
    && LDFLAGS="-latomic -fuse-ld=lld -Wl,--build-id=sha1 -ldl" \
    CC=clang \
    CXX=clang++ \
    PKG_CONFIG_PATH=/opt/lib/pkgconfig:/usr/lib/pkgconfig \
    CARGO_TARGET_DIR=/tmp/cargo-target \
    meson setup ${BUILDDIR} \
      --prefix=/usr/local \
      --sysconfdir=/etc/dnsdist \
      --localstatedir=/var \
      -Dlua=auto \
      -Db_lto=true \
      -Db_lto_mode=thin \
      -Db_pie=true \
      -Ddns-over-https=true \
      -Ddns-over-quic=false \
      -Ddns-over-http3=false \
      -Ddns-over-tls=true \
      -Ddnscrypt=enabled \
      -Ddnstap=enabled \
      -Debpf=enabled \
      -Dtls-gnutls=enabled \
      -Dsnmp=true \
      -Dlibcap=enabled \
      -Dlibsodium=enabled \
      -Dre2=enabled \
      -Dsystemd-service=disabled \
      -Dxsk=enabled \
      -Dh2o=enabled \
      -Dquiche=disabled \
      -Dyaml=enabled \
    && meson compile -C ${BUILDDIR} \
    && meson install -C ${BUILDDIR} --destdir=/tmp/root \
    && strip /tmp/root/usr/local/bin/* \
    && rm -rf /tmp/root/lib # remove systemd unit files, not needed

RUN ldconfig /
RUN rm -rf /tmp/root/usr/local/share/man/*


# Intermediate container with runtime dependencies
FROM --platform=$TARGETPLATFORM debian:stable-slim AS runtime

# Install runtime dependencies
ARG RUN_PKGS="tzdata liblua5.3-0 libsodium23 libprotobuf-c1 libre2-9 libsnmp-base libsnmp40 libedit2 openssl \
              libnghttp2-14 libgnutls30 libxdp1 libbpf1 libfstrm0 libsystemd0 libcap2 libyaml-cpp0.7 libcdb1 liblmdb0"
RUN apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${RUN_PKGS} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd _dnsdist \
    && useradd -g _dnsdist -s /dev/null -d /etc _dnsdist \
    && mkdir -p /opt/lib


# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="$TARGETPLATFORM" \
      description="dnsdist is a highly DNS-, DoS- and abuse-aware loadbalancer. \
                  Its goal in life is to route traffic to the best server, delivering top \
                  performance to legitimate users while shunting or blocking abusive traffic." \
      url="https://dnsdist.org/"

# Environment
ENV TZ Asia/Tokyo

# Publish port
EXPOSE 53/tcp 53/udp 443/tcp 853/tcp 8083/tcp 8443/tcp 8443/udp

# service running
STOPSIGNAL SIGTERM

# Volume
WORKDIR /etc/dnsdist
RUN chmod 1777 /tmp

# Select entrypoint
COPY ["entrypoint.sh", "/usr/bin/"]
HEALTHCHECK CMD ["dnsdist", "-e", "showVersion()", "||", "exit", "1"]
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["dnsdist", "--supervised", "--disable-syslog", "-u", "_dnsdist", "-g", "_dnsdist"]

# Fetch pdns-dnsdist libraries from build image and update ldconfig
COPY --from=build /tmp/root/ /
COPY --from=build /opt/lib/ /opt/lib/
COPY --from=build /opt/include/ /opt/include/
RUN echo "/opt/lib" > /etc/ld.so.conf.d/opt.conf && ldconfig
