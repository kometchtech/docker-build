FROM arm64v8/alpine:latest
LABEL MAINTAINER="kometchtech <kometch@gmail.com>"

ENV DOCKER_IPV6NAT_VERSION v0.3.3
RUN apk add --no-cache --update ip6tables curl \
    && curl -fsSL "https://github.com/robbertkl/docker-ipv6nat/releases/download/${DOCKER_IPV6NAT_VERSION}/docker-ipv6nat.aarch64" -o /docker-ipv6nat \
    && chmod u+x /docker-ipv6nat \
    && apk del --purge curl \
    && rm -rf /var/apk/cache

ENTRYPOINT ["/docker-ipv6nat"]
CMD ["--retry"]
