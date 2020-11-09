FROM arm64v8/alpine:latest AS build

# Environmet
ENV VERSION v0.3
ARG BUILD_PKGS="build-base git libev-dev gmp-dev libmnl-dev libnftnl-dev nftables jansson-dev \
                autoconf automake gawk libtool "
ENV CFLAGS="-O2 -fstack-protector -pthread -fomit-frame-pointer -pipe -fPIC -FORTIFY_SOURCE=2 -fPIE "
ENV CXXFLAGS="${CFLAGS}"
ENV LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now"

# Install from sources
RUN apk add --update --no-cache ${BUILD_PKGS}
RUN git clone -b ${VERSION} --depth=1 https://github.com/zevenet/nftlb.git /usr/local/src
RUN cd /usr/local/src \
    && autoreconf -ivf \
    && ./configure \
    && make -j"$(nproc)" \
    && make install DESTDIR=/tmp/root \
    && ldconfig / || true


# Intermediate container with runtime dependencies
FROM arm64v8/alpine:latest AS runtime

# Install runtime dependencies
ARG RUNTIME_DEPS="libev gmp libmnl libnftnl nftables jansson "

RUN apk add --update --no-cache ${RUNTIME_DEPS} \
  && rm -rf /var/cache/apk/* /usr/local/share/man/*


# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      description="nftlb stands for nftables load balancer, the next generation linux firewall \
                  that will replace iptables is adapted to behave as a complete load balancer \
                  and traffic distributor." \
      url="https://github.com/zevenet/nftlb"

# Environment
ENV TZ Asia/Tokyo

# EXPOSE

# VOLUMES

# select entrypoint
ENTRYPOINT ["nftlb"]

# Fetch Knot DNS from build image
COPY --from=build /tmp/root/ /
RUN ldconfig / || true
