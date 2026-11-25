FROM alpine:latest
LABEL MAINTAINER="kometchtech <kometch@gmail.com>"

ARG TARGETARCH
ENV DOCKER_IPV6NAT_VERSION v0.3.3
RUN apk add --no-cache --update ip6tables curl \
    && case "${TARGETARCH}" in \
         amd64) SUFFIX=amd64 ;; \
         arm64) SUFFIX=aarch64 ;; \
         *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
       esac \
    && curl -fsSL "https://github.com/robbertkl/docker-ipv6nat/releases/download/${DOCKER_IPV6NAT_VERSION}/docker-ipv6nat.${SUFFIX}" -o /docker-ipv6nat \
    && chmod u+x /docker-ipv6nat \
    && apk del --purge curl \
    && rm -rf /var/apk/cache

ENTRYPOINT ["/docker-ipv6nat"]
CMD ["--retry"]

# OCI image metadata
org.opencontainers.image.title="docker-ipv6nat" \
org.opencontainers.image.description="IPv6 NAT container using docker-ipv6nat" \
org.opencontainers.image.url="https://github.com/robbertkl/docker-ipv6nat" \
org.opencontainers.image.source="https://github.com/robbertkl/docker-ipv6nat" \
org.opencontainers.image.documentation="https://github.com/robbertkl/docker-ipv6nat" \
org.opencontainers.image.authors="kometchtech <kometch@gmail.com>" \
org.opencontainers.image.version="${DOCKER_IPV6NAT_VERSION}"
