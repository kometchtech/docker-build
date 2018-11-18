FROM arm64v8/alpine:edge
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64" \
      description="Knot resolver team's things are modified and used."

# Environment
ENV TZ=Asia/Tokyo
ARG VERSION="3.1.0"
ARG BUILD_PKGS="build-base automake autoconf libtool pkgconfig git luajit-dev libuv-dev gnutls-dev jansson-dev userspace-rcu-dev curl vim bsd-compat-headers nettle-dev binutils cmocka-dev"
ARG RUN_PKGS="luajit libuv gnutls jansson bash lua5.1-cqueues lua5.1-http lua5.1-sec lua5.1-socket knot-utils cmocka protobuf-c nettle lua5.1-filesystem libstdc++ ca-certificates "
ARG BUILD_IGNORE="gmp nettle jansson gnutls lua libuv cmocka"
ARG PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"
ARG CFLAGS="-O1 -fstack-protector -pthread -heap-arrays "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,--as-needed"

# export DNS over UDP & TCP, DNS-over-TLS, web interface
EXPOSE 53/UDP 53/TCP 853/TCP 8053/TCP

# Install dependencies and sources
RUN sed -i -e 's/v[[:digit:]]\.[[:digit:]]/edge/g' /etc/apk/repositories \
#    && apk add --update --upgrade apk-tools \
    && apk add --update -t lua5.1-compat5.3 lua5.1-compat53 libressl \
    && apk add --no-cache ${RUN_PKGS} \
    && apk add --no-cache --virtual .build-dep ${BUILD_PKGS} \
    && git clone -b v${VERSION} --recurse-submodules=modules/policy/lua-aho-corasick \
          https://github.com/CZ-NIC/knot-resolver.git /tmp/build \
    && cd /tmp/build \
    && ./scripts/bootstrap-depends.sh /usr/local \
    && make -j $(nproc) install  \
    # Trim down the image
    && cd / \
    && apk del --purge .build-dep \
    && rm -rf /var/cache/apk/* /tmp/build /usr/local/share/man/* 

# add user
RUN adduser -DH knot \
    && mkdir -p /var/run/knot-resolver /var/cache/knot-resolver /etc/knot-resolver \
    && chown -R knot:knot /var/cache/knot-resolver /etc/knot-resolver /var/run/knot-resolver \
    && cp /usr/local/etc/knot-resolver/config.personal /etc/knot-resolver/kresd.conf

# Set the working directory to app home directory
WORKDIR /etc/knot-resolver

# Select entrypoint
#ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["/usr/local/sbin/kresd", "-v", "-f", "1", "-c", "/etc/knot-resolver/kresd.conf", "/run/knot-resolver"]
