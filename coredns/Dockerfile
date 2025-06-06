# syntax = docker/dockerfile:1.4
# Multi-architecture and multi-stage build for CoreDNS

# Build stage with common dependencies
FROM golang:latest AS builder

# Build arguments
ARG VERSION
ARG COMMON_BUILD_PKGS="git ca-certificates"
ARG BUILD_PKGS="automake libtool autoconf pkg-config curl libunbound-dev libhiredis-dev libcap2-bin"

# Build for Linux with static linking
ENV GOOS=linux
ENV CGO_ENABLED=0

# Install build dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get -qqq update && \
    apt-get install -y --no-install-recommends ${COMMON_BUILD_PKGS} ${BUILD_PKGS} && \
    rm -rf /var/lib/apt/lists/*

# Setup workspace
WORKDIR /go/src

# Configure git for large repositories
RUN git config --global http.postBuffer 524288000

# Clone CoreDNS repository with specific version tag
RUN git clone -b v${VERSION} --depth 1 https://github.com/coredns/coredns.git /go/src/github.com/coredns/coredns/

# Build CoreDNS
WORKDIR /go/src/github.com/coredns/coredns
RUN make -j"$(nproc)" && \
    # Remove unnecessary files to reduce image size
    rm -rf man/ test/ doc/

# Runtime stage
FROM scratch

# Environment
ENV TZ Asia/Tokyo

# Publish ports for DNS over UDP & TCP
EXPOSE 53/TCP 53/UDP 443/TCP 443/UDP

# Copy CA certificates and the CoreDNS binary
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /go/src/github.com/coredns/coredns/coredns /coredns

# Set entrypoint
ENTRYPOINT ["/coredns"]

# Labels (placed at the end to minimize impact on build caching)
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      description="CoreDNS (written in Go) chains plugins. Each plugin performs a DNS function." \
      url="https://github.com/coredns/coredns"

