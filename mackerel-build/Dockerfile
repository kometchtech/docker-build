FROM golang:1.21rc3
LABEL maintainer="kometchtech <kometch@gmail.com>" \
    arch="aarch64" \
    version="master"

# Environment
ENV TZ=Asia/Tokyo
ARG BUILD_PKGS="git"
ARG RUN_PKGS=""
ARG CFLAGS=""
ARG LDFLAGS=""

WORKDIR /go/src/
RUN apt-get update && apt-get install git \
		&& go get -d github.com/mackerelio/mackerel-agent \
		&& go build -o build/mackerel-agent \
  -ldflags="\
    -X github.com/mackerelio/mackerel-agent/version.GITCOMMIT `git rev-parse --short HEAD` \
    -X github.com/mackerelio/mackerel-agent/version.VERSION   `git describe --tags --abbrev=0 | sed 's/^v//' | sed 's/\+.*$$//'` " \
  github.com/mackerelio/mackerel-agent
