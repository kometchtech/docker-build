# Environment
FROM arm64v8/alpine:edge
LABEL maintainer="kometchtech <kometch@gmail.com>" \
  arch="aarch64" \
  version="github-master"
ENV DIBBLER 1.0.1
ENV DEBIAN_FRONTEND noninteractive
ENV TZ Asia/Tokyo
ENV BUILD_PKGS build-base ca-certificates curl automake autoconf unzip
ENV RUN_PKGS coreutils
ENV CFLAGS "-O3 -fPIC -mtune=native -march=native"
ENV LDFLAGS ""

# config
WORKDIR /etc/dibbler
VOLUME ["/etc/dibbler"]

# export TCP and UDP
EXPOSE 547/TCP 547/UDP

# Select entrypoint
CMD ["/usr/local/sbin/dibbler-server", "run"]

# compile and install
RUN mkdir -p /usr/src \
&& apk add --no-cache ${BUILD_PKGS} ${RUN_PKGS} \ 
  && curl -LO "https://github.com/tomaszmrugalski/dibbler/archive/master.zip" \
  && unzip -q "master.zip" -d /usr/src \ 
  && rm -f "master.zip" \
  && cd /usr/src/dibbler-master \
  && ./configure CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \ 
  --sysconfdir=/etc/dibbler \ 
  --enable-maintainer-mode \
  && make -j "$(nproc)" \ 
  && make install \ 
  && apk del --purge ${BUILD_PKGS} \
  && cd / \
  && rm -rf /usr/src \ 
    && /var/cache/apk/* /usr/local/share/man \
    && cp /usr/local/share/doc/dibbler/examples/server.conf /etc/dibbler/server.conf \
    && mkdir -p /var/lib/dibbler \
    && ln -snf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
    