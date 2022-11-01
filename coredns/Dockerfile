# syntax = docker/dockerfile:experimental
# 1st build
FROM --platform=$TARGETPLATFORM golang:latest as build-env

ARG TARGETPLATFORM
ARG VERSION="1.5.0"
ARG BUILD_PKGS="git automake libtool autoconf pkg-config curl libunbound-dev libhiredis-dev "

ENV GOOS linux
# ENV GOARCH arm64
WORKDIR /go/src
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ${BUILD_PKGS} \
    && rm -rf /var/lib/apt/lists/*
RUN git config --global http.postBuffer 524288000
RUN git clone -b v${VERSION} --depth=1 https://github.com/coredns/coredns.git /go/src/github.com/coredns/coredns/
#RUN cd /go/src/github.com/coredns/coredns/ \
## enable external plugsins
#   && echo "redisc:github.com/miekg/redis" | tee -a plugin.cfg \
#   && echo "fanout:github.com/networkservicemesh/fanout" | tee -a plugin.cfg
RUN cd /go/src/github.com/coredns/coredns/ \
   && go generate \
#   && go mod tidy \
   && go build \
   && make


# 2nd build
FROM scratch
LABEL maintainer="kometchtech <kometch@gmail.com>"
LABEL arch="$TARGETPLATFORM"
LABEL description="CoreDNS (written in Go) chains plugins. Each plugin performs a DNS function."
LABEL url="https://github.com/coredns/coredns"

# Environment
ENV PATH "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENV TZ Asia/Tokyo

# publish port DNS over UDP & TCP
EXPOSE 53/TCP
EXPOSE 53/UDP

# copy file
COPY --from=build-env /go/src/github.com/coredns/coredns/coredns /coredns

# Select entrypoint
WORKDIR /etc/coredns
ENTRYPOINT ["/coredns"]
