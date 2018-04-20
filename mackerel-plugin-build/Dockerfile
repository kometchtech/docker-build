FROM golang:1.10
LABEL maintainer="kometchtech <kometch@gmail.com>" \
    arch="aarch64" \
    version="master"

# Environment
ENV TZ=Asia/Tokyo
ARG BUILD_PKGS="build-essential devscripts"
ARG RUN_PKGS=""
ARG CFLAGS=""
ARG LDFLAGS=""

WORKDIR /root
RUN apt-get -qq update \
    && apt-get -qq install -y ${BUILD_PKGS} 
