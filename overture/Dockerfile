FROM alpine AS build

ENV VERSION="v1.5-rc2"
ENV ARCH="arm64"
ENV BUILD_PKGS="curl unzip "

WORKDIR /tmp
RUN apk add --no-cache --update ${BUILD_PKGS} 
RUN curl -fsSLO https://github.com/shawn1m/overture/releases/download/${VERSION}/overture-linux-${ARCH}.zip \
    && unzip overture-linux-${ARCH}.zip \
    && rm -rf overture-linux-${ARCH}.zip 


# 2nd build
FROM scratch
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      description="Overture is a DNS server/forwarder/dispatcher written in Go." \
      url="https://github.com/shawn1m/overture"

# Environment
ENV TZ Asia/Tokyo

# Entrypoint
ENTRYPOINT ["/usr/local/bin/overture"]

WORKDIR /etc/overture
COPY --from=build /tmp/overture-linux-arm64 /usr/local/bin/overture
COPY --from=build /tmp/*sample /etc/overture/
COPY --from=build /tmp/config.json /etc/overture/

