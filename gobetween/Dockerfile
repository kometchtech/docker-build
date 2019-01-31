# 1st build 
FROM golang:alpine as build

# https://golang.org/doc/install/source#environment
ENV CGO_ENABLED 0
ENV GOOS linux
ENV GOARCH arm64
ENV VERSION 0.6.1
ARG BUILD_PKGS="git make automake autoconf libressl curl binutils "

WORKDIR /go/src/github.com/yyyar/
RUN apk add --update --no-cache ${BUILD_PKGS}
RUN git clone -b ${VERSION} --depth 1 https://github.com/yyyar/gobetween.git /go/src/github.com/yyyar/
RUN git config http.postBuffer 524288000 \
  && cd /go/src/github.com/yyyar/ \
  && make deps
RUN mkdir -p /tmp/root/etc/gobetween \
  && make -j"$(nproc)" install DESTDIR=/tmp/root
RUN strip /tmp/root/usr/local/bin/gobetween

# final build
FROM scratch
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      description="Modern & minimalistic load balancer for the Cloud era" \
      url="https://github.com/yyyar/gobetween"

# command
ENTRYPOINT ["gobetween"]

# Multi stage build
WORKDIR /etc/gobetween/
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /tmp/root /
