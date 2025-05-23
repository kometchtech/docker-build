# syntax = docker/dockerfile:experimental

# Common build stage with shared dependencies
FROM rust:latest AS common-build

# Common build dependencies
ARG COMMON_BUILD="clang lld cmake ninja-build python3-yaml python3-pip python3-venv"
ARG VERSION
ARG LUAVER=lua5.3
ARG CC=clang
ARG CXX=clang++
ARG H2O_VERSION=v2.2.6

# Set up Python venv with meson
RUN apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${COMMON_BUILD} \
    && python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir 'meson>=1.3.0' 'pyyaml' \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /usr/src /tmp/root/etc/dnsdist /build /h2o

# Setup env
ENV PATH="/opt/venv/bin:$PATH"

# Main build stage
FROM common-build AS build

# Additional build dependencies
ARG BUILD_PKGS="meson pkgconf libboost-all-dev libsodium-dev libre2-dev libsnmp-dev libedit-dev libnghttp2-dev libgnutls28-dev \
               libxdp-dev libbpf-dev libfstrm-dev libsystemd-dev libcap-dev liblmdb-dev libluajit-5.1-dev liblua5.3-dev \
               libssl-dev libwslay-dev ragel "
ARG LUAVER=lua5.3
ARG VERSION

# Install additional dev packages
RUN apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${BUILD_PKGS} \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends lib${LUAVER}-dev \
    && rm -rf /var/lib/apt/lists/*

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

# Download dnsdist source
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
      -Ddns-over-https=enabled \
      -Ddns-over-quic=disabled \
      -Ddns-over-http3=disabled \
      -Ddns-over-tls=enabled \
      -Ddnscrypt=enabled \
      -Ddnstap=enabled \
      -Debpf=enabled \
      -Dtls-gnutls=enabled \
      -Dsnmp=enabled \
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
    && rm -rf /tmp/root/lib \
    && ldconfig / \
    && rm -rf /tmp/root/usr/local/share/man/* \
    && rm -rf /tmp/root/usr/local/share/doc/*

# Runtime dependencies stage
FROM debian:stable-slim AS runtime

# Install runtime dependencies
ARG RUN_PKGS="tzdata liblua5.3-0 ca-certificates libcap2-bin libyaml-cpp0.7 libcdb1 liblmdb0 libluajit-5.1-2 \
              libfstrm0 libedit2 libnghttp2-14 libgnutls30 libsnmp40 libsodium23 libre2-9 libxdp1 libbpf1 tini"

RUN apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${RUN_PKGS} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd _dnsdist \
    && useradd -g _dnsdist -s /dev/null -d /etc _dnsdist \
    && mkdir -p /opt/lib

# Final stage
FROM runtime

# Environment
ENV TZ Asia/Tokyo

# Publish ports
EXPOSE 53/tcp 53/udp 443/tcp 853/tcp 8083/tcp 8443/tcp 8443/udp

# Service running
STOPSIGNAL SIGTERM

# Volume and working directory setup
WORKDIR /etc/dnsdist
RUN chmod 1777 /tmp

# Copy files from build stage
COPY --from=build /tmp/root/ /
COPY --from=build /opt/lib/ /opt/lib/
COPY --from=build /opt/include/ /opt/include/
COPY entrypoint.sh /usr/local/bin/

# Configure dynamic libraries
RUN echo "/opt/lib" > /etc/ld.so.conf.d/opt.conf && ldconfig

# Health check and entrypoint
HEALTHCHECK CMD ["dnsdist", "-e", "showVersion()", "||", "exit", "1"]
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["dnsdist", "--supervised", "--disable-syslog", "-u", "_dnsdist", "-g", "_dnsdist"]

# Labels placed at end to minimize impact on build caching
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      description="dnsdist is a highly DNS-, DoS- and abuse-aware loadbalancer. \
                  Its goal in life is to route traffic to the best server, delivering top \
                  performance to legitimate users while shunting or blocking abusive traffic." \
      url="https://dnsdist.org/"
