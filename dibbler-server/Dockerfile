# Environment
FROM arm64v8/debian:9.3-slim
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64" \
      version="github-master"
ENV DIBBLER 1.0.1
ENV DEBIAN_FRONTEND noninteractive
ENV TZ Asia/Tokyo
ENV BUILD_PKGS build-essential ca-certificates curl automake autoconf unzip
ENV RUN_PKGS coreutils
ENV CFLAGS "-Ofast -fPIC"
ENV LDFLAGS ""

# config
WORKDIR /etc/dibbler
VOLUME ["/etc/dibbler"]

# export TCP and UDP
EXPOSE 547/TCP 547/UDP
CMD ["/usr/local/sbin/dibbler-server", "run"]

# compile and install
RUN apt-get -qq update \
    && apt-get -qq install -y --no-install-recommends $BUILD_PKGS $RUN_PKGS \ 
    && curl -LO "https://github.com/tomaszmrugalski/dibbler/archive/master.zip" \
    && unzip "master.zip" \ 
    && rm -f "master.zip" \
    && cd dibbler-master \
    && ./configure CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \ 
      --sysconfdir=/etc/dibbler \ 
      --enable-maintainer-mode \
  && make -j "$(nproc)" \ 
  && make install \ 
  && apt-get purge --auto-remove -y ${BUILD_PKGS} \
  && apt-get clean \ 
  && rm -rf \ 
      "dibbler-master" \ 
      /var/lib/apt/lists/* \
  && cp /usr/local/share/doc/dibbler/examples/server.conf /etc/dibbler/server.conf \
  && mkdir /var/lib/dibbler \
  && ln -snf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
