# 1st build 
FROM golang:alpine as build

# https://golang.org/doc/install/source#environment
ENV CGO_ENABLED 0
ENV GOOS linux
ENV GOARCH arm64
ARG VERSION="0.6.11"
WORKDIR /go/src/github.com/nadoo/
RUN apk add --update --no-cache git build-base
RUN git clone -b v${VERSION} --depth=1 https://github.com/nadoo/glider.git /go/src/github.com/nadoo/glider
RUN cd /go/src/github.com/nadoo/glider \
    && go build -v -ldflags="-s -w"

# 2nd build
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
RUN apk --no-cache add tzdata zip ca-certificates

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

# command
#CMD ["gobetween", "from-file", "/etc/gobetween/gobetween.toml"]
ENTRYPOINT ["/glider"]

# Multi stage build
WORKDIR /etc/glider/
COPY --from=runtime /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /go/src/github.com/nadoo/glider/glider /glider

