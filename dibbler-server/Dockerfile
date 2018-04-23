FROM arm64v8/alpine:edge
LABEL maintainer="kometchtech <kometch@gmail.com>" \
  arch="aarch64" \
  version="github-master"

# Environment
ARG DIBBLER=1.0.1
ARG DEBIAN_FRONTEND=noninteractive
ARG BUILD_PKGS="build-base ca-certificates curl automake autoconf unzip linux-headers gawk"
ARG RUN_PKGS="coreutils libstdc++ libgcc"
ARG CFLAGS="-O0 -fPIC -pipe -mtune=native -march=native"
ARG LDFLAGS=""
ENV TZ=Asia/Tokyo

# config
WORKDIR /etc/dibbler
VOLUME ["/etc/dibbler"]

# export TCP and UDP
EXPOSE 547/TCP 547/UDP

# Select entrypoint
CMD ["/usr/local/sbin/dibbler-server", "run"]

# compile and install
RUN echo $TZ > /etc/timezone \
    && mkdir -p /usr/src \
    && apk add --update --no-cache ${BUILD_PKGS} ${RUN_PKGS} \ 
    && curl -LO "https://github.com/tomaszmrugalski/dibbler/archive/master.zip" \
    && unzip -q "master.zip" -d /usr/src \ 
    && rm -f "master.zip" \
    && cd /usr/src/dibbler-master \
    && ./configure CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \ 
    --sysconfdir=/etc/dibbler \ 
    --enable-maintainer-mode \
    && make -j "$(nproc)" \ 
    && make install-strip \ 
    && apk del --purge ${BUILD_PKGS} \
    && cd / \
    && rm -rf /usr/src /var/cache/apk/* /usr/local/share/man \
    && cp /usr/local/share/doc/dibbler/examples/server.conf /etc/dibbler/server.conf \
    && mkdir -p /var/lib/dibbler \
    && ln -snf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
    
