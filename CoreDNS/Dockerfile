FROM golang:alpine AS build-env
# Environment
LABEL maintainer="kometchtech <kometch@gmail.com>" \
    arch="aarch64" \
    version="1.0.6"
ENV COREDNS 1.0.6
ENV TZ Asia/Tokyo
# 1st build
ADD . /work
WORKDIR /work
RUN make -j ${nproc}

# multi-stage build
FROM alpine:latest

# Only need ca-certificates & openssl if want to use DNS over TLS (RFC 7858).
RUN apk --no-cache add bind-tools ca-certificates openssl && update-ca-certificates

COPY --from=build-env /work/coredns /usr/local/bin/coredns
# export DNS over UDP & TCP
EXPOSE 53 53/UDP
VOLUME [ "/etc/coredns" ]
# Select entrypoint
CMD ["coredns", "-c", "/etc/coredns/corefile"]
