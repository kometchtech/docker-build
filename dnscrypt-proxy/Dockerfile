# 1st build 
FROM arm64v8/golang:alpine as build

# https://golang.org/doc/install/source#environment
ENV CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=arm64 \
    VERSION=2.0.18
WORKDIR /go/src/github.com/jedisct1/
RUN apk add --no-cache git 
RUN git clone -b ${VERSION} https://github.com/jedisct1/dnscrypt-proxy /go/src/github.com/jedisct1/
RUN cd /go/src/github.com/jedisct1/dnscrypt-proxy \
  && go build -v -ldflags="-s -w" -o /go/bin/dnscrypt-proxy

# 2nd build
FROM scratch
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64" \
      description="A flexible DNS proxy, with support for modern encrypted DNS protocols such as DNSCrypt v2 and DNS-over-HTTP/2." \
      url="https://github.com/jedisct1/dnscrypt-proxy"

# Environmet
ENV TZ=Asia/Tokyo

# export DNS over UDP & TCP
EXPOSE 53/TCP 53/UDP 

# Multi stage build
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ 
COPY --from=build /go/bin/dnscrypt-proxy /usr/local/bin/
WORKDIR /etc/dnscrypt-proxy/
COPY --from=build /go/src/github.com/jedisct1/dnscrypt-proxy/example-* /etc/dnscrypt-proxy/

# command
CMD [ "dnscrypt-proxy", "-config", "/etc/dnscrypt-proxy/example-dnscrypt-proxy.toml"]
