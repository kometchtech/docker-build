# syntax = docker/dockerfile:experimental

# Common build stage with shared dependencies
FROM rust:latest AS common-build

# Common build dependencies including base tools
ARG COMMON_BUILD="clang lld cmake ninja-build python3-yaml python3-pip python3-venv jq patchelf"
ARG CC=clang
ARG CXX=clang++

# Set up Python venv with meson
RUN apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${COMMON_BUILD} \
    && python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir 'meson>=1.3.0' 'pyyaml' \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /usr/src /tmp/root/etc/dnsdist /build /h2o /quiche

# Setup env
ENV PATH="/opt/venv/bin:$PATH"
ENV CC=clang
ENV CXX=clang++

# Quiche build stage
FROM common-build AS quiche-build

ARG QUICHE_VERSION=0.24.2

# Download and build quiche
RUN cd /quiche \
    && curl -SL "https://github.com/cloudflare/quiche/archive/refs/tags/${QUICHE_VERSION}.tar.gz" -o quiche.tar.gz \
    && tar xf quiche.tar.gz --strip-components=1 \
    && rm quiche.tar.gz \
    # Disable SONAME in the quiche shared library
    && sed -i 's/ffi = \["dep:cdylib-link-lines"\]/ffi = \[\]/' quiche/Cargo.toml \
    && sed -i 's,cdylib_link_lines::metabuild();,//cdylib_link_lines::metabuild();,' quiche/src/build.rs \
    && RUST_BACKTRACE=1 cargo build --release --no-default-features --features ffi,boringssl-boring-crate --package quiche \
    # Handle SONAME if present (debian specific)
    && if objdump -p target/release/libquiche.so 2>/dev/null | grep -F -q SONAME; then \
         patchelf --set-soname libdnsdist-quiche.so target/release/libquiche.so; \
       fi \
    && mkdir -p /opt/include /opt/lib \
    && install -m644 quiche/include/quiche.h /opt/include/ \
    && install -m644 target/release/libquiche.so /opt/lib/libdnsdist-quiche.so

# Create quiche pkg-config file
RUN mkdir -p /opt/lib/pkgconfig && \
    echo "Name: quiche" > /opt/lib/pkgconfig/quiche.pc && \
    echo "Description: quiche library" >> /opt/lib/pkgconfig/quiche.pc && \
    echo "URL: https://github.com/cloudflare/quiche" >> /opt/lib/pkgconfig/quiche.pc && \
    echo "Version: ${QUICHE_VERSION}" >> /opt/lib/pkgconfig/quiche.pc && \
    echo "Cflags: -I/opt/include" >> /opt/lib/pkgconfig/quiche.pc && \
    echo "Libs: -L/opt/lib -ldnsdist-quiche" >> /opt/lib/pkgconfig/quiche.pc && \
    ls -la /opt/lib/ && \
    ls -la /opt/include/ && \
    cat /opt/lib/pkgconfig/quiche.pc

# H2O build stage
FROM common-build AS h2o-build

ARG H2O_VERSION=v2.2.6

# Build h2o
RUN cd /h2o \
    && curl -SL "https://github.com/h2o/h2o/archive/refs/tags/${H2O_VERSION}.tar.gz" -o h2o.tar.gz \
    && tar xf h2o.tar.gz --strip-components=1 \
    && rm h2o.tar.gz \
    && cmake -DCMAKE_INSTALL_PREFIX=/opt \
       -DWITH_MRUBY=OFF \
       -DWITH_PICOTLS=OFF \
       -DCMAKE_C_FLAGS="-mno-outline-atomics" \
       -DWITH_BUNDLED_SSL=OFF . \
    && make -j$(nproc) \
    && make install

# Create h2o pkg-config file
RUN mkdir -p /opt/lib/pkgconfig && \
    echo "prefix=/opt" > /opt/lib/pkgconfig/libh2o-evloop.pc && \
    echo "exec_prefix=\${prefix}" >> /opt/lib/pkgconfig/libh2o-evloop.pc && \
    echo "libdir=\${exec_prefix}/lib" >> /opt/lib/pkgconfig/libh2o-evloop.pc && \
    echo "includedir=\${prefix}/include" >> /opt/lib/pkgconfig/libh2o-evloop.pc && \
    echo "Name: libh2o-evloop" >> /opt/lib/pkgconfig/libh2o-evloop.pc && \
    echo "Description: H2O HTTP library" >> /opt/lib/pkgconfig/libh2o-evloop.pc && \
    echo "Version: ${H2O_VERSION#v}" >> /opt/lib/pkgconfig/libh2o-evloop.pc && \
    echo "Libs: -L\${libdir} -lh2o-evloop" >> /opt/lib/pkgconfig/libh2o-evloop.pc && \
    echo "Cflags: -I\${includedir}" >> /opt/lib/pkgconfig/libh2o-evloop.pc && \
    ls -la /opt/lib/ && \
    cat /opt/lib/pkgconfig/libh2o-evloop.pc

# Main build stage
FROM common-build AS build

# Build version argument
ARG VERSION
ARG LUAVER=lua5.3

# Additional build dependencies
ARG BUILD_PKGS="pkgconf libboost-dev libsodium-dev libprotobuf-c-dev libre2-dev libsnmp-dev \
               libedit-dev libssl-dev libnghttp2-dev libgnutls28-dev libxdp-dev libbpf-dev ca-certificates libfstrm-dev \
               libsystemd-dev libcap-dev libyaml-cpp-dev libcdb-dev liblmdb-dev libluajit-5.1-dev pkg-config"

# Install additional dev packages
RUN apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${BUILD_PKGS} \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends lib${LUAVER}-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy pre-built dependencies
COPY --from=h2o-build /opt/lib /opt/lib
COPY --from=h2o-build /opt/include /opt/include
COPY --from=quiche-build /opt/lib /opt/lib
COPY --from=quiche-build /opt/include /opt/include

# Download dnsdist source
RUN curl -SL "https://downloads.powerdns.com/releases/dnsdist-${VERSION}.tar.xz" -o dnsdist.tar.xz \
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

# Build Env
ARG DNSDIST_LDFLAGS="-latomic -fuse-ld=lld -Wl,--build-id=sha1 -ldl -L/opt/lib"
ARG DNSDIST_CPPFLAGS="-I/opt/include"

# Build dnsdist with meson
RUN cd /usr/src \
    && BUILDDIR=$(mktemp -d) \
    && export PKG_CONFIG_PATH=/opt/lib/pkgconfig:/usr/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/aarch64-linux-gnu/pkgconfig \
    && export CARGO_TARGET_DIR=/tmp/cargo-target \
    && pkg-config --cflags --libs quiche || true \
    && pkg-config --cflags --libs libh2o-evloop || true \
    && meson setup ${BUILDDIR} \
      --prefix=/usr/local \
      --sysconfdir=/etc/dnsdist \
      --localstatedir=/var \
      -Dc_args="${DNSDIST_CPPFLAGS}" \
      -Dcpp_args="${DNSDIST_CPPFLAGS}" \
      -Dc_link_args="${DNSDIST_LDFLAGS}" \
      -Dcpp_link_args="${DNSDIST_LDFLAGS}" \
      -Dlua=auto \
      -Db_lto=true \
      -Db_lto_mode=thin \
      -Db_pie=true \
      -Ddns-over-https=enabled \
      -Ddns-over-quic=enabled \
      -Ddns-over-http3=enabled \
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
      -Dquiche=enabled \
      -Dyaml=enabled \
    && meson compile -C ${BUILDDIR} \
    && meson install -C ${BUILDDIR} --destdir=/tmp/root \
    && strip /tmp/root/usr/local/bin/* \
    && rm -rf /tmp/root/lib \
    && rm -rf /tmp/root/usr/local/share/man/* \
    && rm -rf /tmp/root/usr/local/share/doc/* \
    && rm -rf ${BUILDDIR} /tmp/cargo-target

# Runtime stage
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

# Copy files from build stage
COPY --from=build /tmp/root/ /
COPY --from=build /opt /opt
COPY entrypoint.sh /usr/local/bin/

# Configure dynamic libraries
RUN echo "/opt/lib" > /etc/ld.so.conf.d/opt.conf && \
    ldconfig

# Set up working directory and permissions
WORKDIR /etc/dnsdist
RUN chmod 1777 /tmp \
    && chmod +x /usr/local/bin/entrypoint.sh

# Publish ports
EXPOSE 53/tcp 53/udp 443/tcp 853/tcp 8083/tcp 8443/tcp 8443/udp

# Service running
STOPSIGNAL SIGTERM

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
