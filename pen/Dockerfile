FROM arm64v8/alpine:latest
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      version="0.34.1" \
      description="This is pen, a load balancer for udp and tcp based protocols such as \
		   dns, http or smtp. It allows several servers to appear as one to the \
		   outside and automatically detects servers that are down and distributes \
		   clients among the available servers. This gives high availability and \
		   scalable performance." \
      url="https://github.com/UlricE/pen"

# Environment
ENV TZ Asia/Tokyo
ARG BUILD_PKGS="build-base git libtool autoconf automake gawk linux-headers libressl-dev"
ARG RUN_PKGS="tzdata libressl"
ENV CFLAGS "-O2 -fstack-protector -pthread -fomit-frame-pointer -pipe -fPIC -FORTIFY_SOURCE=2 -fPIE \
            -ftree-vectorize -ftree-slp-vectorize "
ENV LDFLAGS "-Wl,--as-needed -Wl,-z,relro -Wl,-z,now"


# config
WORKDIR /etc/pen
VOLUME ["/etc/pen"]

# select ENTRYPOINT
ENTRYPOINT ["pen", "-f"]

# source build and install
RUN apk add --update --no-cache  ${BUILD_PKGS} ${RUN_PKGS} \
    && git clone --depth=1 https://github.com/UlricE/pen.git /usr/local/src \
    && cd /usr/local/src \
    && ./bootstrap.sh \
    && ./configure --with-ssl --with-poll --with-kqueue --with-epoll \
    && make -j"$(nproc)" \
    && make install \
    && apk del --purge ${BUILD_PKGS} \
    && cd / \
    && rm -rf /usr/local/src /var/cache/apk/* /usr/local/share/man


