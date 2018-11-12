# 1st build 
FROM arm64v8/golang as build-env

RUN apt-get -q -y update \
    && apt-get install -q -y git-core make gcc libtool autoconf pkg-config 
RUN go get -u -v github.com/coredns/coredns || true
RUN cd  /go/src/github.com/coredns/coredns/ \
    && set -x \
    && make -j all \
    && CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -v -ldflags="-s -w" 

# 2nd build
FROM scratch
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64" \
      description="CoreDNS (written in Go) chains plugins. Each plugin performs a DNS function." \
      url="https://github.com/coredns/coredns"

# Environment
ENV TZ=Asia/Tokyo

COPY --from=build-env /etc/ssl/certs /etc/ssl/certs
COPY --from=build-env /go/src/github.com/coredns/coredns/coredns /usr/local/bin/coredns
# export DNS over UDP & TCP
EXPOSE 53 53/UDP
# Select entrypoint
CMD ["coredns", "-dns.port", "53"]
