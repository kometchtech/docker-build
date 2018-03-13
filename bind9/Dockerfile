FROM arm64v8/alpine:edge
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64" \
      description="BIND9 for Aarch64"

# Environment
ENV TZ Asia/Tokyo

# Select entrypoint
EXPOSE 53/tcp 53/udp
CMD ["named", "-c", "/etc/bind/named.conf", "-g", "-u", "named"]


# install
RUN apk --no-cache --update add bind \
    && ln -snf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
