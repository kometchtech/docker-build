# 1st build 
FROM arm64v8/golang:alpine as build-env

ARG VERSION="v1.3.1"
WORKDIR /go/src
RUN apk add --no-cache --update build-base git automake libtool autoconf pkgconfig 
RUN git clone -b ${VERSION} https://github.com/coredns/coredns.git /go/src/github.com/coredns/coredns/ \
    && cd  /go/src/github.com/coredns/coredns/ \
    && make -j"$(procs)" all \
    && CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -v -ldflags="-s -w"

# 2nd build
FROM scratch
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      description="CoreDNS (written in Go) chains plugins. Each plugin performs a DNS function." \
      url="https://github.com/coredns/coredns"

# Environment
ENV TZ Asia/Tokyo

# export DNS over UDP & TCP
EXPOSE 53/TCP 53/UDP

# Select entrypoint
WORKDIR /etc/coredns
ENTRYPOINT ["/coredns"]

# copy file 
COPY --from=build-env /etc/ssl/certs /etc/ssl/certs
COPY --from=build-env /go/src/github.com/coredns/coredns/coredns /coredns
