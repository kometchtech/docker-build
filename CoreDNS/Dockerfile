# Environment
FROM arm64v8/debian:9.3-slim
LABEL maintainer="kometchtech <kometch@gmail.com>" \
    arch="aarch64" \
    version="1.0.6"
ENV DIBBLER 1.0.6
ENV DEBIAN_FRONTEND noninteractive
ENV TZ Asia/Tokyo
ENV BUILD_PKGS build-essential ca-certificates curl automake autoconf unzip
ENV RUN_PKGS coreutils
ENV CFLAGS "-Os -fPIC"
ENV LDFLAGS ""

# export DNS over UDP & TCP, DNS-over-TLS, web interface
EXPOSE 53/UDP 53
# Select entrypoint
CMD ["coredns", "-c", "/etc/coredns/corefile"]
