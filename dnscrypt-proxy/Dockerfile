# syntax = docker/dockerfile:experimental

# Build stage
FROM golang:alpine AS builder

# Set build arguments
ARG VERSION=""

# Set build environment
ENV CGO_ENABLED=0 GOOS=linux

# Install git
RUN apk add --no-cache git tzdata

# Clone repository
WORKDIR /src
RUN git clone -b ${VERSION} --depth=1 https://github.com/DNSCrypt/dnscrypt-proxy .

# Build the application with cache mount for faster builds
RUN --mount=type=cache,target=/root/.cache/go-build \
    cd /src/dnscrypt-proxy && \
    go build -v -tags "osusergo netgo" \
             -ldflags '-extldflags "-static -s -w"' \
             -o /go/bin/dnscrypt-proxy

# Final stage
FROM scratch

# Environment variables
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    TZ=Asia/Tokyo

# Expose DNS ports
EXPOSE 53/TCP 53/UDP

# Copy SSL certificates and binary from builder
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /go/bin/dnscrypt-proxy /
COPY --from=builder /src/dnscrypt-proxy/example-* /etc/dnscrypt-proxy/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Set working directory
WORKDIR /etc/dnscrypt-proxy/

# Define default command
CMD ["/dnscrypt-proxy", "-config", "/etc/dnscrypt-proxy/example-dnscrypt-proxy.toml"]

# Add metadata labels (at the end to minimize layer impact)
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      description="A flexible DNS proxy, with support for modern encrypted DNS protocols such as DNSCrypt v2 and DNS-over-HTTP/2." \
      url="https://github.com/jedisct1/dnscrypt-proxy"
