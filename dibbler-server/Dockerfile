FROM arm64v8/alpine:latest AS build

# Environment
ENV VERSION master
#ENV VERSION RELEASE1.0.1
ARG BUILD_PKGS="build-base clang ca-certificates automake autoconf linux-headers gawk git libtool lld "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIC -FORTIFY_SOURCE=2 -fPIE "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now -fuse-ld=lld "
ENV CC="clang"
ENV CXX="clang++"

# compile and install
RUN mkdir -p /usr/src /tmp/root/etc/dibbler/ \
    && apk add --update --no-cache ${BUILD_PKGS}
RUN git clone -b ${VERSION} --depth=1 https://github.com/tomaszmrugalski/dibbler.git /usr/src
RUN cd /usr/src \
    && autoreconf -if \
    && ./configure \
      CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" \
      --sysconfdir=/etc/dibbler \
    && make -j "$(nproc)" install DESTDIR=/tmp/root
RUN cp /tmp/root/usr/local/share/doc/dibbler/examples/server.conf /tmp/root/etc/dibbler/server.conf \
    && rm -rf /tmp/root/usr/local/share/man/* /tmp/root/usr/local/share/doc/*


# runtime container build
FROM arm64v8/alpine:latest AS runtime

# install runtime dependencies
ARG RUN_PKGS="libstdc++ libgcc tzdata"

RUN apk add --update --no-cache ${RUN_PKGS} \
    && rm -rf /var/cache/apk/* /usr/local/share/man/* \
    && mkdir -p /var/lib/dibbler

# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="Aarch64" \
      description="Portable DHCPv6 implementation" \
      url="http://klub.com.pl/dhcpv6/"

# Environment
ENV TZ Asia/Tokyo

# volume
WORKDIR /etc/dibbler
VOLUME ["/etc/dibbler", "/var/lib/dibbler"]

# export TCP and UDP
EXPOSE 547/TCP 547/UDP

# Select entrypoint
CMD ["/usr/local/sbin/dibbler-server", "run"]

# Fetch binary images
COPY --from=build /tmp/root /
RUN ldconfig / || true
