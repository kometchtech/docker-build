# syntax = docker/dockerfile:experimental
# 1st build
FROM --platform=$TARGETPLATFORM golang:latest as build

# https://golang.org/doc/install/source#environment
ENV CGO_ENABLED 0
ENV GOOS linux
#ENV GOARCH arm64
ARG VERSION=2.0.25
WORKDIR /go/src/github.com/jedisct1/
RUN --mount=type=cache,target=/root/.cache/go-build \
    apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*
RUN git clone -b ${VERSION} --depth=1 https://github.com/jedisct1/dnscrypt-proxy /go/src/github.com/jedisct1/
RUN cd /go/src/github.com/jedisct1/dnscrypt-proxy \
    && go build -v -tags "osusergo netgo" \
                 -ldflags '-extldflags "-static -s -w"' \
                 -o /go/bin/dnscrypt-proxy

# 2nd build
FROM scratch
LABEL maintainer="kometchtech <kometch@gmail.com>"
LABEL arch="$TARGETPLATFORM"
LABEL description="A flexible DNS proxy, with support for modern encrypted DNS protocols such as DNSCrypt v2 and DNS-over-HTTP/2."
LABEL url="https://github.com/jedisct1/dnscrypt-proxy"

# Environmet
ENV PATH "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENV TZ Asia/Tokyo

# publish port DNS over UDP & TCP
EXPOSE 53/TCP
EXPOSE 53/UDP

# Multi stage build
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /go/bin/dnscrypt-proxy /
COPY --from=build /go/src/github.com/jedisct1/dnscrypt-proxy/example-* /etc/dnscrypt-proxy/
WORKDIR /etc/dnscrypt-proxy/

# command
CMD [ "/dnscrypt-proxy", "-config", "/etc/dnscrypt-proxy/example-dnscrypt-proxy.toml"]
