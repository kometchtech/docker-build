FROM arm64v8/alpine:latest
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64" \
      description="A flexible DNS proxy, with support for modern encrypted DNS protocols such as DNSCrypt v2 and DNS-over-HTTP/2." \
      url="https://github.com/jedisct1/dnscrypt-proxy"

# Environment
ENV TZ=Asia/Tokyo
ARG VERSION="2.0.17"
ARG BUILD_PKGS="curl tar" 
ARG RUN_PKGS="ca-certificates tzdata"

# download
RUN apk --no-cache add ${BUILD_PKGS} ${RUN_PKGS} \
    && curl -L https://github.com/jedisct1/dnscrypt-proxy/releases/download/${VERSION}/dnscrypt-proxy-linux_arm64-${VERSION}.tar.gz -o dnscrypt-proxy.tar.gz \
    && tar xf dnscrypt-proxy.tar.gz \
    && rm dnscrypt-proxy.tar.gz \
    && cd linux-arm64 \
    && cp dnscrypt-proxy /usr/bin \
    && mkdir -p /etc/dnscrypt-proxy \
    && cp example-* /etc/dnscrypt-proxy \
    && cp example-dnscrypt-proxy.toml /etc/dnscrypt-proxy/dnscrypt-proxy.toml \
    && apk del --purge ${BUILD_PKGS} \
    && cd .. \
    && rm -rf linux-arm64 


# export DNS over UDP & TCP
EXPOSE 53/TCP 53/UDP 443/TCP 443/UDP
# expose VOLUME
VOLUME [ "/etc/dnscrypt-proxy" ]
# command
CMD [ "dnscrypt-proxy", "-config", "/etc/dnscrypt-proxy/dnscrypt-proxy.toml"]
