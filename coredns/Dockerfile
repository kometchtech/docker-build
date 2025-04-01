# syntax = docker/dockerfile:1.4
# Multi-architecture and multi-stage build for CoreDNS

# Build stage
FROM golang:latest AS builder

# Build arguments
ARG VERSION
ARG BUILD_PKGS="git automake libtool autoconf pkg-config curl libunbound-dev libhiredis-dev ca-certificates libcap2-bin"
# Build for Linux
ENV GOOS=linux

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends ${BUILD_PKGS} && \
    rm -rf /var/lib/apt/lists/*

# Setup workspace
WORKDIR /go/src

# Configure git for large repositories
RUN git config --global http.postBuffer 524288000

# Clone CoreDNS repository
RUN git clone -b v${VERSION} --depth 1 https://github.com/coredns/coredns.git /go/src/github.com/coredns/coredns/

# Build CoreDNS
WORKDIR /go/src/github.com/coredns/coredns
RUN make -j"$(nproc)"

# Runtime stage
FROM gcr.io/distroless/static-debian12:nonroot

# Working directory
WORKDIR /

# Environment
ENV PATH "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENV TZ Asia/Tokyo

# Publish ports for DNS over UDP & TCP
EXPOSE 53/TCP 53/UDP 443/TCP 443/UDP

# Copy CA certificates and the CoreDNS binary
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /go/src/github.com/coredns/coredns/coredns /coredns

# Run as non-root user
USER nonroot:nonroot

# Set entrypoint
ENTRYPOINT ["/coredns"]

# Labels (placed at the end to minimize impact on build caching)
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      description="CoreDNS (written in Go) chains plugins. Each plugin performs a DNS function." \
      url="https://github.com/coredns/coredns"

