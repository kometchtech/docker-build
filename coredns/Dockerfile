# syntax = docker/dockerfile:experimental
# build stage
FROM golang:latest as build-env

ARG VERSION
ARG BUILD_PKGS="git automake libtool autoconf pkg-config curl libunbound-dev libhiredis-dev ca-certificates libcap2-bin "

ENV GOOS linux
WORKDIR /go/src
RUN apt-get update && \
    apt-get install -y --no-install-recommends ${BUILD_PKGS} && \
    rm -rf /var/lib/apt/lists/*
RUN git config --global http.postBuffer 524288000
RUN git clone -b v${VERSION} https://github.com/coredns/coredns.git /go/src/github.com/coredns/coredns/
#RUN git clone  https://github.com/coredns/coredns.git /go/src/github.com/coredns/coredns/
RUN cd /go/src/github.com/coredns/coredns/ && \
    make -j"$(nproc)"

# runtime image
FROM gcr.io/distroless/static-debian12:nonroot
LABEL maintainer="kometchtech <kometch@gmail.com>"
LABEL description="CoreDNS (written in Go) chains plugins. Each plugin performs a DNS function."
LABEL url="https://github.com/coredns/coredns"

WORKDIR /
# Environment
ENV PATH "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENV TZ Asia/Tokyo

# publish port DNS over UDP & TCP
EXPOSE 53/TCP 53/UDP 443/TCP 443/udp

# copy file
COPY --from=build-env /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build-env /go/src/github.com/coredns/coredns/coredns /coredns

# User
USER nonroot:nonroot

# Select entrypoint
ENTRYPOINT ["/coredns"]
