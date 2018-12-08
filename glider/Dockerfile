# 1st build 
FROM golang:alpine as build

# https://golang.org/doc/install/source#environment
ENV CGO_ENABLED 0 
ENV GOOS linux 
ENV GOARCH arm64 
ENV VERSION 0.6.9
WORKDIR /go/src/github.com/nadoo/
RUN apk add --update --no-cache git build-base
RUN go get -u github.com/nadoo/glider
RUN cd /go/bin/ \
  && strip glider

# 2nd build
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
RUN apk --no-cache add tzdata zip ca-certificates
#WORKDIR /usr/share/zoneinfo
#RUN zip -r -0 /zoneinfo.zip .

# final build
FROM scratch
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      description="glider is a forward proxy with multiple protocols support, \
        and also a dns forwarding server with ipset management features(like dnsmasq)." \
      url="https://github.com/nadoo/glider"

# Environmet
ENV TZ Asia/Tokyo

# export DNS over UDP & TCP
#EXPOSE 53/TCP 53/UDP

# command
#CMD ["gobetween", "from-file", "/etc/gobetween/gobetween.toml"]
ENTRYPOINT ["/glider"]

# Multi stage build
WORKDIR /etc/glider/
COPY --from=runtime /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /go/bin/glider /glider
#ENV ZONEINFO /zoneinfo.zip
#COPY --from=runtime /zoneinfo.zip /

