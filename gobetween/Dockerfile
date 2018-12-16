# 1st build 
FROM golang:alpine as build

# https://golang.org/doc/install/source#environment
ENV CGO_ENABLED 0 
ENV GOOS linux 
ENV GOARCH arm64 
ENV VERSION 0.6.1
WORKDIR /go/src/github.com/yyyar/
RUN apk add --update --no-cache git make automake autoconf libressl curl
RUN git clone --depth 1 https://github.com/yyyar/gobetween.git /go/src/github.com/yyyar/
RUN git config http.postBuffer 524288000 \
  && cd /go/src/github.com/yyyar/ \
  && make deps
RUN mkdir -p /tmp/root/etc/gobetween \
  && make -j"$(nproc)" install DESTDIR=/tmp/root 

# 2nd build
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
RUN apk add --update --no-cache tzdata ca-certificates

# final build
FROM scratch
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      description="Modern & minimalistic load balancer for the Cloud era" \
      url="https://github.com/yyyar/gobetween"

# Environmet
ENV TZ Asia/Tokyo

# command
ENTRYPOINT ["gobetween"]

# Multi stage build
WORKDIR /etc/gobetween/
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /tmp/root /
