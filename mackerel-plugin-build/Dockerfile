FROM golang:1.10
LABEL maintainer="kometchtech <kometch@gmail.com>" \
    arch="aarch64" \
    version="master"

# Environment
ENV TZ Asia/Tokyo
ENV BUILD_PKGS build-essential devscripts
ENV RUN_PKGS ''
ENV CFLAGS ''
ENV LDFLAGS ''

WORKDIR /root
RUN \
apt-get -qq update && \
apt-get -qq install -y ${BUILD_PKGS} 
