FROM arm64v8/alpine:latest
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64" \
      version="github-master" \
      description="Portable DHCPv6 implementation"

# Environment
ENV DIBBLER 1.0.1
ENV TZ Asia/Tokyo
ARG BUILD_PKGS="build-base ca-certificates curl automake autoconf unzip linux-headers gawk"
ARG RUN_PKGS="coreutils libstdc++ libgcc"
ENV CFLAGS="-O2 -fPIC -pipe -mtune=native -march=native"
ENV LDFLAGS="-Wl,-z -Wl,relro -Wl,-z -Wl,now -Wl,--as-needed"

# config
WORKDIR /etc/dibbler
VOLUME ["/etc/dibbler", "/var/lib/dibbler"]

# export TCP and UDP
EXPOSE 547/TCP 547/UDP

# Select entrypoint
CMD ["/usr/local/sbin/dibbler-server", "run"]

# compile and install
RUN mkdir -p /usr/src /var/lib/dibbler \
    && apk add --update --upgrade apk-tools \
    && apk add --update --no-cache ${BUILD_PKGS} ${RUN_PKGS} \ 
    && curl -LO "https://github.com/tomaszmrugalski/dibbler/archive/master.zip" \
    && unzip -q "master.zip" -d /usr/src \ 
    && rm -f "master.zip" \
    && cd /usr/src/dibbler-master \
    && ./configure CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \ 
    --sysconfdir=/etc/dibbler \ 
    --enable-maintainer-mode \
    && make -j "$(nproc)" install \ 
    && apk del --purge ${BUILD_PKGS} \
    && cd / \
    && rm -rf /usr/src /var/cache/apk/* /usr/local/share/man \
    && cp /usr/local/share/doc/dibbler/examples/server.conf /etc/dibbler/server.conf 
    
