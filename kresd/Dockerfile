FROM arm64v8/alpine:edge
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64" \
      description="Knot resolver team's things are modified and used."

# Environment
ENV TZ=Asia/Tokyo
ARG VERSION="2.3.0"
ARG BUILD_PKGS="build-base automake autoconf libtool pkgconfig git luajit-dev libuv-dev gnutls-dev jansson-dev userspace-rcu-dev curl vim bsd-compat-headers tzdata"
ARG RUN_PKGS="luajit libuv gnutls jansson bash libstdc++ lua-cqueues lua-http lua-sec lua-socket"
ARG BUILD_IGNORE="gmp nettle jansson gnutls lua libuv cmocka"
ARG PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"
ARG CFLAGS="-Og -ftree-vectorize -fstack-protector"
ARG LDFLAGS="-Wl,--as-needed"

# export DNS over UDP & TCP, DNS-over-TLS, web interface
EXPOSE 53/UDP 53/TCP 853/TCP 8053/TCP

# Install dependencies and sources
RUN apk add -t lua-compat53 \
      && apk --update add ${RUN_PKGS} \
      && apk add --virtual build-dep ${BUILD_PKGS} \
      && git clone --depth 1 --recurse-submodules=modules/policy/lua-aho-corasick \
            https://github.com/CZ-NIC/knot-resolver.git /tmp/build \
      && cd /tmp/build \
      && ./scripts/bootstrap-depends.sh /usr/local \
      && make -j ${nproc} install \
      # Trim down the image
      && cd / \
      && apk del --purge build-dep \
      && rm -rf /var/cache/apk/* /tmp/build 

# Select entrypoint
RUN mkdir -p /etc/knot-resolver \
    && cp /usr/local/etc/knot-resolver/config.personal /etc/knot-resolver/kresd.conf
CMD ["/usr/local/sbin/kresd", "-c", "/etc/knot-resolver/kresd.conf"]
