# syntax = docker/dockerfile:experimental
# 1st build
FROM arm64v8/golang:1.13 as build-env

ARG VERSION="1.5.0"
ARG BUILD_PKGS="git automake libtool autoconf pkg-config curl libunbound-dev libhiredis-dev "

ENV CGO_ENABLED 0
ENV GOOS linux
ENV GOARCH arm64
WORKDIR /go/src
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ${BUILD_PKGS}
RUN git config --global http.postBuffer 524288000
RUN git clone -b v${VERSION} https://github.com/coredns/coredns.git /go/src/github.com/coredns/coredns/
RUN cd /go/src/github.com/coredns/coredns/ \
   && make all


# 2nd build
FROM scratch
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      description="CoreDNS (written in Go) chains plugins. Each plugin performs a DNS function." \
      url="https://github.com/coredns/coredns"

# Environment
ENV TZ Asia/Tokyo

# publish port DNS over UDP & TCP
EXPOSE 53/TCP 53/UDP

# service running
STOPSIGNAL SIGTERM

# Select entrypoint
WORKDIR /etc/coredns
ENTRYPOINT ["/coredns"]

# copy file 
COPY --from=build-env /etc/ssl/certs /etc/ssl/certs
COPY --from=build-env /go/src/github.com/coredns/coredns/coredns /coredns
