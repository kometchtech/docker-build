FROM golang:alpine AS build-env
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64" \
      description="A flexible DNS proxy, with support for modern encrypted DNS protocols such as DNSCrypt v2 and DNS-over-HTTP/2."

# Environment
ENV TZ Asia/Tokyo
ENV BUILD_PKGS git 
ENV GOOS=linux GOARCH=arm64 GOROOT=/root GOPATH=${HOME}

RUN apk --no-cache add ${BUILD_PKGS} \
    && mkdir dnscrypt-proxy-src \
    && cd dnscrypt-proxy-src \
    && go get github.com/jedisct1/dnscrypt-proxy \
    && cd dnscrypt-proxy \
    && go clean \
    && go build -ldflags="-s -w" -o $GOPATH/linux-amd64/dnscrypt-proxy \
    && cp $GOPATH/src/dnscrypt-proxy/example-* $GOPATH/linux-arm64 \
    && cp $GOPATH/src/systemd/* $GOPATH/linux-arm64 

# 2nd stage build
FROM arm64v8/alpine:edge
ENV GOPATH=${HOME}

COPY --from=build-env /work/coredns /root/go/linux-arm64
# export DNS over UDP & TCP
EXPOSE 443 443/UDP
# expose VOLUME
VOLUME [ "/root/go/linux-arm64" ]
# command
CMD [ "/root/go/linux-arm64/dnscrypt-proxy" ]