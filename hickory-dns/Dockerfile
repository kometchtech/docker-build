# syntax = docker/dockerfile:experimental

ARG VERSION="0.25.0-alpha.4"
ARG SOURCE_FILE="https://github.com/hickory-dns/hickory-dns/archive/refs/tags/v${VERSION}.tar.gz"
# wget https://github.com/hickory-dns/hickory-dns/archive/refs/tags/v${VERSION}.tar.gz -O - | sha256sum
#ARG SOURCE_SHA256="c5ac7115fc577aa8097e9f3efa8e119cef8adc95588b9ab1be599144858f16aa"

FROM --platform=$TARGETPLATFORM rust:latest AS build-env

ARG VERSION
ARG SOURCE_FILE
#ARG SOURCE_SHA256

# https://docs.rs/crate/hickory-dns/0.24.2/features
## version 0.24.2
#ARG DEFAULT_FEATURES="ascii-art,resolver,sqlite"
#ARG FEATURES="dns-over-h3,dns-over-quic,dns-over-rustls,dns-over-https-rustls,dnssec,dnssec-openssl,recursor,$DEFAULT_FEATURES"
## version 0.25.0-alpha.5
# https://docs.rs/crate/hickory-dns/0.25.0-alpha.5/features
ARG DEFAULT_FEATURES="ascii-art,resolver,rustls-platform-verifier,sqlite"
ARG FEATURES="tls-aws-lc-rs,https-aws-lc-rs,quic-aws-lc-rs,h3-aws-lc-rs,tls-ring,https-ring,quic-ring,h3-ring,serde,$DEFAULT_FEATURES"
ARG BUILD_PKGS="libssl-dev "

WORKDIR /workspace
RUN \
    wget "${SOURCE_FILE}" -O /tmp/hickory-dns.tar.gz; \
#    echo "${SOURCE_SHA256}  /tmp/hickory-dns.tar.gz" > /tmp/hickory-dns.tar.gz.sha256sum; \
#    sha256sum -s -c -w /tmp/hickory-dns.tar.gz.sha256sum; \
    tar --strip-components=1 --directory /workspace -xzvf /tmp/hickory-dns.tar.gz; \
    rm /tmp/hickory-dns.tar.gz;

# Install build dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y ${BUILD_BASE} ${BUILD_PKGS} \
    && rm -rf /var/lib/apt/lists/*

RUN cargo fetch
# https://users.rust-lang.org/t/sigsegv-with-program-linked-against-openssl-in-an-alpine-container/52172
RUN RUSTFLAGS="-C target-feature=-crt-static" cargo build --release --no-default-features --features $FEATURES

FROM --platform=$TARGETPLATFORM debian:stable-slim AS runtime

ARG VERSION
ARG SOURCE_FILE
ARG SOURCE_SHA256
ARG BUILD_DATE

# Metadata
LABEL org.label-schema.vendor="hickory-dns" \
    org.label-schema.url="https://github.com/hickory-dns/hickory-dns#readme" \
    org.label-schema.name="hickory-dns" \
    org.label-schema.description="hickory-dns DNS server" \
    org.label-schema.version=${VERSION} \
    org.label-schema.vcs-url=${SOURCE_FILE} \
    # This one is not in the spec
    org.label-schema.vcs-sha256=${SOURCE_SHA256} \
    # org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.docker.schema-version="1.0" \
    \
    com.docker.extension.publisher-url="https://github.com/hickory-dns" \
    \
    org.opencontainers.image.title="Docker hickory-dns DNS server" \
    org.opencontainers.image.description="hickory-dns DNS server" \
    org.opencontainers.image.authors="benjaminfry@me.com" \
    org.opencontainers.image.url="https://github.com/hickory-dns/hickory-dns#readme" \
    org.opencontainers.image.documentation="https://github.com/hickory-dns/hickory-dns#readme" \
    org.opencontainers.image.source="https://github.com/hickory-dns/hickory-dns" \
    org.opencontainers.image.vendor="hickory-dns" \
    org.opencontainers.image.licenses="MIT or Apache-2.0" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.version=${VERSION} \
    # org.opencontainers.image.revision=${VCS_REF} \
    org.opencontainers.image.ref.name="${VERSION}"

# https://github.com/mischov/meeseeks/issues/98#issuecomment-636615680
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y libssl3 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r nobody

USER nobody:nobody
COPY --from=build-env \
     /workspace/target/release/hickory-dns /usr/bin

# Quickly test the binary is "working" and has no linked libs errors
RUN hickory-dns --version

ENTRYPOINT [ "hickory-dns" ]
