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
RUN rake build:server_dist && rm -rf dist/server/lib

# Keep the runtime image separate from the build toolchain.
FROM debian:stable-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /usr/lib/stork-server/hooks

# Copy the upstream distribution files into their expected locations.
COPY --from=builder /src/stork/dist/server/ /

# Listen on container interfaces so the published port is reachable.
ENV STORK_REST_HOST=0.0.0.0
EXPOSE 8080
ENTRYPOINT ["/usr/bin/stork-server"]
