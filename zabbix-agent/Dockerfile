# syntax = docker/dockerfile:experimental
FROM arm64v8/alpine:latest AS build

# source build
ARG MAJOR_VERSION=4.0
ARG ZBX_VERSION=${MAJOR_VERSION}.5
ENV ZBX_VERSION=${ZBX_VERSION} ZBX_SOURCES=${ZBX_SOURCES}
ENV ZBX_SOURCES=http://repo.zabbix.com/zabbix/${MAJOR_VERSION}/ubuntu/pool/main/z/zabbix/zabbix_${ZBX_VERSION}.orig.tar.gz
ENV BUILD_PKGS="build-base clang autoconf automake openssl-dev pcre-dev coreutils libevent-dev curl lld "
ARG CFLAGS="-O2 -pthread -pipe -fPIC -fPIC -FORTIFY_SOURCE=2 -fPIE "
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-O2 -Wl,--as-needed -Wl,-z,relro -Wl,-z,now -fuse-ld=lld "
ENV CC="clang"
ENV CXX="clang++"

# dependencies package
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --update -t .build-dep ${BUILD_PKGS}
RUN cd /tmp/ \
    && curl -L ${ZBX_SOURCES} -o zabbix-${ZBX_VERSION}.tar.gz \
    && tar xf zabbix-${ZBX_VERSION}.tar.gz \
    && rm -rf zabbix-${ZBX_VERSION}.tar.gz
# build
RUN cd /tmp/zabbix-${ZBX_VERSION} \
    && ./configure \
       --datadir=/usr/lib \
       --libdir=/usr/lib/zabbix \
       --prefix=/usr \
       --sysconfdir=/etc/zabbix \
       --prefix=/usr \
       --enable-agent \
       --enable-ipv6 \
       --silent \
       CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" \
    && make -j"$(nproc)" -s 1>/dev/null \
    && make install DESTDIR=/tmp/root
RUN ldconfig /
RUN cd /tmp/zabbix-${ZBX_VERSION} \
    && rm -rf /tmp/root/usr/share/man /tmp/root/usr/local/share/man \
    && cp src/zabbix_agent/zabbix_agentd /tmp/root/usr/sbin/zabbix_agentd \
    && cp src/zabbix_get/zabbix_get /tmp/root/usr/bin/zabbix_get \
    && cp src/zabbix_sender/zabbix_sender /tmp/root/usr/bin/zabbix_sender \
    && cp conf/zabbix_agentd.conf /tmp/root/etc/zabbix/zabbix_agentd.conf


# Environment
FROM arm64v8/alpine:latest AS runtime

ARG RUN_PKGS="bash iputils libevent pcre tzdata"

# runtime build
RUN addgroup zabbix && \
    adduser -S \
            -D -G zabbix \
            -h /var/lib/zabbix/ \
            zabbix && \
    mkdir -p /etc/zabbix /etc/zabbix/zabbix_agentd.d /var/lib/zabbix /var/lib/zabbix/enc /var/lib/zabbix/modules && \
    apk add --update --no-cache ${RUN_PKGS} && \
    rm -rf /var/cache/apk/*

# Final container
FROM runtime
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      description="zabbix official customize" \
      url="https://www.zabbix.com/"

# Environment
ENV TERM=xterm \
    ZBX_TYPE=agent \
    ZBX_OPT_TYPE=none
ENV TZ Asia/Tokyo

# service running
STOPSIGNAL SIGTERM

# Expose
EXPOSE 10050/TCP

WORKDIR /var/lib/zabbix

VOLUME ["/etc/zabbix/zabbix_agentd.d", "/var/lib/zabbix/enc", "/var/lib/zabbix/modules"]
COPY ["docker-entrypoint.sh", "/usr/bin/"]
ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]

# Fetch app and libraries from build image
COPY --from=build /tmp/root /
RUN chown -R zabbix:root /etc/zabbix \
    && chown -R zabbix:root /var/lib/zabbix \
    && chmod +x /usr/bin/docker-entrypoint.sh \
    && ldconfig /
