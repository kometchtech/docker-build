FROM arm64v8/alpine:latest
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64" \
      description="Knot DNS team's things are modified and used." \
      url="https://www.knot-dns.cz/"

# Select entrypoint
WORKDIR /root

# Expose port
EXPOSE 53/UDP 53/TCP

# Environment
ENV VERSION="2.7.3" \
    TZ=Asia/Tokyo
ARG BUILD_PKGS="build-base automake autoconf libtool pkgconfig userspace-rcu-dev lmdb-dev gnutls-dev libedit-dev libidn-dev curl gawk"
ARG RUNTIME_PKGS="userspace-rcu lmdb gnutls libedit libidn tzdata"
ARG CFLAGS="-Os -fomit-frame-pointer -pipe -mtune=native -march=native"
ARG CXXFLAGS="-Os"
ARG LDFLAGS="-Wl,-s,-flto,--gc-sections,-z -Wl,relro -Wl,-z -Wl,now -Wl,--as-needed"

# Install dependencies and sources
RUN apk add --update --upgrade apk-tools \
  && apk add --update ${BUILD_PKGS} ${RUNTIME_PKGS} \
# Compile sources
  && curl -fL https://secure.nic.cz/files/knot-dns/knot-${VERSION}.tar.xz -o knot.tar.gz \
  && mkdir -p /knot-src/ \
  && tar xf knot.tar.gz --strip-components=1 -C /knot-src/ \
  && rm -rf knot.tar.gz \
  && cd /knot-src \
  && ./configure \
      --prefix=/ \
      --with-configdir=/etc/knot \
      --with-rundir=/run/knot \
      --enable-shared \
      --disable-static \
      --enable-fastparser \
      --disable-documentation \
      --enable-reuseport=auto \
      --enable-recvmmsg=auto \
      --enable-systemd=no \
      CFLAGS="${CFLAGS}" CXXFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}"  \
      && make -j "$(nproc)" \
      && make install \
# Trim down the image
  && cd \
  && rm -rf /knot-src \
  && apk del --purge ${BUILD_PKGS} \
  && mkdir -p /var/lib/knot/zones /var/lib/knot/zones/timers \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Use example configuration and zone
RUN mv /etc/knot/knot.sample.conf /etc/knot/knot.conf && \
echo '  - domain: example.com\n    file: "/etc/knot/example.com.zone"' >> /etc/knot/knot.conf

# select entrypoint
ADD entrypoint.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/entrypoint.sh
CMD ["/usr/local/sbin/entrypoint.sh"]
