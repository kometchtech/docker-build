FROM arm64v8/alpine:edge
LABEL maintainer="kometchtech <kometch@gmail.com>" \
    arch="aarch64" \
    version="1.2.0"
ENV COREDNS 1.2.0 \
    TZ Asia/Tokyo

# Only need ca-certificates & openssl if want to use DNS over TLS (RFC 7858).
RUN apk --no-cache add bind-tools ca-certificates openssl && update-ca-certificates

COPY ./coredns /usr/local/bin/coredns
# export DNS over UDP & TCP
EXPOSE 53 53/UDP
VOLUME [ "/etc/coredns" ]
# Select entrypoint
CMD ["coredns", "-conf", "/etc/coredns/corefile"]
