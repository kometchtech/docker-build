FROM arm64v8/alpine:edge
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64" \
      description="Knot resolver team's things are modified and used."

# Environment
ENV TZ=Asia/Tokyo
ARG VERSION="2.4.1"
ARG BUILD_PKGS="build-base automake autoconf libtool pkgconfig git luajit-dev libuv-dev gnutls-dev jansson-dev userspace-rcu-dev curl vim bsd-compat-headers nettle-dev binutils"
ARG RUN_PKGS="luajit libuv gnutls jansson bash lua5.1-cqueues lua5.1-http lua5.1-sec lua5.1-socket knot-utils cmocka protobuf-c nettle lua5.1-filesystem libstdc++"
ARG BUILD_IGNORE="gmp nettle jansson gnutls lua libuv cmocka"
ARG PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"
ARG CFLAGS="-O2 -ftree-vectorize -D_FORTIFY_SOURCE=2 -fstack-protector -g -pthread"
ARG LDFLAGS="-Wl,--as-needed"

# export DNS over UDP & TCP, DNS-over-TLS, web interface
EXPOSE 53/UDP 53/TCP 853/TCP 8053/TCP

# Install dependencies and sources
RUN sed -i -e "s/3.7/3.8/" /etc/apk/repositories \
      && apk add --update --upgrade apk-tools \
      && apk add -t lua5.1-compat5.3 lua5.1-compat53 \
      && apk --update add ${RUN_PKGS} \
      && apk add --virtual build-dep ${BUILD_PKGS} \
      && git clone --depth 1 --recurse-submodules=modules/policy/lua-aho-corasick \
            https://github.com/CZ-NIC/knot-resolver.git /tmp/build \
      && cd /tmp/build \
      && ./scripts/bootstrap-depends.sh /usr/local \
      && make -j $(nproc) install  \
      # Trim down the image
      && cd / \
      && apk del --purge build-dep \
      && rm -rf /var/cache/apk/* /tmp/build /usr/local/share/man/*

# Select entrypoint
RUN mkdir -p /etc/knot-resolver \
    && cp /usr/local/etc/knot-resolver/config.personal /etc/knot-resolver/kresd.conf \
    && kdig DNSKEY . @k.root-servers.net +noall +answer | grep "DNSKEY[[:space:]]257" > /etc/knot-resolver/root.keys
CMD ["/usr/local/sbin/kresd", "-v", "-f", "1", "-c", "/etc/knot-resolver/kresd.conf"]
