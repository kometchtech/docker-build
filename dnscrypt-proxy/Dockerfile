# 1st build 
FROM arm64v8/golang:alpine as build
ENV CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=arm64
WORKDIR /go/src/github.com/jedisct1/
RUN apk add --no-cache git 
RUN git clone https://github.com/jedisct1/dnscrypt-proxy /go/src/github.com/jedisct1/
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
EXPOSE 53/TCP 53/UDP 443/TCP 443/UDP

# Recommend package
#RUN apk --no-cache add ca-certificates tzdata
ADD ca-certificates.crt /etc/ssl/certs/

# Multi stage build
COPY --from=build /go/bin/dnscrypt-proxy /usr/local/bin/
WORKDIR /etc/dnscrypt-proxy/
COPY --from=0 /go/src/github.com/jedisct1/dnscrypt-proxy/example-* /etc/dnscrypt-proxy/

# command
CMD [ "dnscrypt-proxy", "-config", "/etc/dnscrypt-proxy/dnscrypt-proxy.toml"]
