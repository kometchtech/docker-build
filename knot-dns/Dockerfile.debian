FROM debian:stretch-slim
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      arch="aarch64" \
      description="Knot DNS team's things are modified and used." \
      url="https://www.knot-dns.cz/"

# Select entrypoint
WORKDIR /root

# Expose port
EXPOSE 53/UDP 53/TCP

# Environment
ENV VERSION="2.7.1" \
    TZ=Asia/Tokyo
ARG DEBIAN_FRONTEND=noninteractive
ARG BUILD_PKGS="git-core make gcc libtool autoconf pkg-config liburcu-dev liblmdb-dev libgnutls28-dev libedit-dev libidn11-dev curl gawk g++"
ARG RUNTIME_PKGS="liburcu4 liblmdb0 libgnutls30 libedit2 libidn11 tzdata"
ARG CFLAGS="-Os -fstack-protector -pthread -mtune=native -march=native"
ARG CXXFLAGS="-Os"
ARG LDFLAGS="-Wl,-z -Wl,relro -Wl,-z -Wl,now -Wl,--as-needed"

# Install dependencies and sources
RUN apt-get -q -y update \
  && apt-get install -q -y ${BUILD_PKGS} ${RUNTIME_PKGS} \
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
  && apt-get purge -q -y ${BUILD_PKGS} \
  && apt-get autoremove -q -y \
  && apt-get clean \
  && mkdir -p /var/lib/knot/zones /var/lib/knot/zones/timers \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Use example configuration and zone
RUN mv /etc/knot/knot.sample.conf /etc/knot/knot.conf && \
echo '  - domain: example.com\n    file: "/etc/knot/example.com.zone"' >> /etc/knot/knot.conf

# select entrypoint
ADD entrypoint.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/entrypoint.sh
CMD ["/usr/local/sbin/entrypoint.sh"]
