FROM arm64v8/debian:9.3-slim
MAINTAINER kometchtech <kometch@gmail.com>
WORKDIR /
ENV NSD_VERSION 4.1.20
ENV DEBIAN_FRONTEND noninteractive
ADD echo /bin/echo
RUN echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup
RUN apt-get update \
    && apt-get -qq install -y --no-install-recommends apt-utils \
      openssl \
      libevent-2.0-5 \
    && apt-get -y -qq install --no-install-recommends \
      build-essential \
#      ldnsutils \
      libssl-dev \
      libevent-dev \
      coreutils \
      curl \
      automake \
      autoconf \
    && curl -fSL "http://www.nlnetlabs.nl/downloads/nsd/nsd-${NSD_VERSION}.tar.gz" -o "nsd-${NSD_VERSION}.tar.gz" \
    && tar xf "nsd-${NSD_VERSION}.tar.gz" \
    && rm -f "nsd-${NSD_VERSION}.tar.gz" 
WORKDIR /nsd-${NSD_VERSION}
RUN autoreconf -if \
  && ./configure \
      --prefix=/usr/local \
      --sysconfdir=/etc \
      --localstatedir=/var \
      --enable-ratelimit \
      --with-zonesdir=/etc/nsd/zones \
      --with-libevent \
      --with-ssl \
      --enable-pie \
      --enable-relro-now \
      --enable-packed \
      CFLAGS="-Ofast -flto -fPIE -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -fstack-protector-strong -Wformat -Werror=format-security" \
      LDFLAGS="-Wl,-z,now -Wl,-z,relro" \
	&& make -j "$(nproc)" \
  && make install \
  && rm -rf \
      "/nsd-${NSD_VERSION}" \
      /var/lib/apt/lists/* \
  && useradd -s /usr/sbin/nologin -d /etc/nsd nsd \
  && chown nsd:nsd /var/db/nsd \
  && chmod 0700 /var/db/nsd
WORKDIR /etc/nsd
RUN mv nsd.conf.sample nsd.conf
VOLUME ["/etc/nsd", "/var/log/nsd", "/etc/nsd/zones"]
EXPOSE 53 53/udp
ENTRYPOINT ["/usr/local/sbin/nsd", "-d"]
