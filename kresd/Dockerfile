FROM arm64v8/alpine:edge
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64" \
      description="Knot resolver team's things are modified and used."

# Environment
ENV TZ Asia/Tokyo
ENV BUILD_PKGS build-base automake autoconf libtool pkgconfig git luajit-dev libuv-dev gnutls-dev jansson-dev userspace-rcu-dev curl vim bsd-compat-headers
ENV RUN_PKGS luajit libuv gnutls jansson bash libstdc++ lua-cqueues lua-http lua-sec lua-socket
ENV BUILD_IGNORE gmp nettle jansson gnutls lua libuv cmocka
ENV PKG_CONFIG_PATH /usr/local/lib/pkgconfig
ENV CFLAGS -Ofast -ftree-vectorize -fstack-protector -g
ENV LDFLAGS -Wl,--as-needed

# export DNS over UDP & TCP, DNS-over-TLS, web interface
EXPOSE 53/UDP 53/TCP 853/TCP 8053/TCP

# Select entrypoint
WORKDIR /etc/knot-resolver
COPY "config.docker" "/etc/knot-resolver/kresd.conf"
CMD ["/usr/local/sbin/kresd", "-c", "/etc/knot-resolver/kresd.conf"]

# Install dependencies and sources
RUN \
apk add -t lua-compat53 && \
apk --update add ${RUN_PKGS} && \
apk add --virtual build-dep ${BUILD_PKGS} && \
git clone --depth 1 --recurse-submodules=modules/policy/lua-aho-corasick \
https://github.com/CZ-NIC/knot-resolver.git /tmp/build && \
cd /tmp/build && \
./scripts/bootstrap-depends.sh /usr/local && \
make -j ${nproc} install && \
# Trim down the image
cd / && \
apk del --purge build-dep && \
rm -rf /var/cache/apk/* /tmp/build \
&& ln -snf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
