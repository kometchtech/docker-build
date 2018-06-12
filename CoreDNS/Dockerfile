FROM golang:alpine AS build-env
LABEL maintainer="kometchtech <kometch@gmail.com>" \
    arch="aarch64" \
    version="1.1.3"
ENV COREDNS 1.1.3 \
    TZ Asia/Tokyo

# 1st stage build
ADD . /work
WORKDIR /work
RUN make -j ${nproc}

# 2nd stage build
FROM arm64v8/alpine:edge

# Only need ca-certificates & openssl if want to use DNS over TLS (RFC 7858).
RUN apk --no-cache add bind-tools ca-certificates openssl && update-ca-certificates

COPY --from=build-env /work/coredns /usr/local/bin/coredns
# export DNS over UDP & TCP
EXPOSE 53 53/UDP
VOLUME [ "/etc/coredns" ]
# Select entrypoint
CMD ["coredns", "-conf", "/etc/coredns/corefile"]
