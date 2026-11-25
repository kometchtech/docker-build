# Provide the Go toolchain for the source build.
FROM golang:latest AS go

# Build Stork from the ISC release source using the upstream Rake tasks.
FROM node:current AS builder
COPY --from=go /usr/local/go /usr/local/go
ENV PATH="/usr/local/go/bin:/root/go/bin:${PATH}"

# Install the tools needed by the Stork build system.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ruby ruby-dev rake python3 python3-venv python3-dev python3-wheel \
    default-jre-headless build-essential git wget unzip \
    && rm -rf /var/lib/apt/lists/*

# CI supplies VERSION from the image directory.
ARG VERSION=2.6.0
WORKDIR /src/stork

# Download and unpack the matching ISC source release.
RUN wget -q "https://downloads.isc.org/isc/stork/${VERSION}/stork-${VERSION}.tar.gz" -O /tmp/stork.tar.gz \
    && tar -xzf /tmp/stork.tar.gz --strip-components=1 \
    && rm /tmp/stork.tar.gz

# Remove systemd units: Debian uses a merged /usr layout, and the container
# starts the binary directly rather than using systemd.
RUN rake build:agent_dist && rm -rf dist/agent/lib

# Keep the runtime image separate from the build toolchain.
FROM debian:stable-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates procps \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/lib/stork-agent /usr/lib/stork-agent/hooks

# Copy the upstream distribution files into their expected locations.
COPY --from=builder /src/stork/dist/agent/ /

# Agent listener and Kea/BIND 9 Prometheus exporters.
EXPOSE 8080 9547 9119
ENTRYPOINT ["/usr/bin/stork-agent"]

# OCI image metadata
ARG VERSION
org.opencontainers.image.title="ISC Stork Agent" \
org.opencontainers.image.description="ISC Stork Agent for monitoring Kea and BIND 9" \
org.opencontainers.image.url="https://stork.readthedocs.io/" \
org.opencontainers.image.source="https://github.com/isc-projects/stork" \
org.opencontainers.image.documentation="https://stork.readthedocs.io/" \
org.opencontainers.image.authors="kometchtech <kometch@gmail.com>" \
org.opencontainers.image.version="${VERSION}"
