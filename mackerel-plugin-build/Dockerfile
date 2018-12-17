FROM golang:latest
LABEL maintainer="kometchtech <kometch@gmail.com>" \
    arch="aarch64" 

# Environment
ENV VERSION v0.53.0
ARG BUILD_PKGS="build-essential devscripts"

WORKDIR /go/src
RUN apt-get -qq update \
    && apt-get -qq install -y ${BUILD_PKGS} 
RUN git clone -b ${VERSION} --depth=1  https://github.com/mackerelio/mackerel-agent-plugins.git 
WORKDIR /go/src/mackerel-agent-plugins
RUN sed -i -e 's/386/arm/g' Makefile && \
    sed -i -e 's/amd64/arm64/g' Makefile && \
    sed -i -e 's/amd64/arm64/g' packaging/deb-v2/debian/control && \
    make deps && \
    make deb-v2
