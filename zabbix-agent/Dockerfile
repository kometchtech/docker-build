FROM arm64v8/alpine:edge
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      description="zabbix official customize"

ARG APK_FLAGS_COMMON="-q"
ARG APK_FLAGS_PERSISTANT="${APK_FLAGS_COMMON} --no-cache"
ARG APK_FLAGS_DEV="${APK_FLAGS_COMMON} --no-cache"
ENV BUILD_PKGS bash iputils libevent pcre
ENV RUN_PKGS alpine-sdk autoconf automake openssl-dev pcre-dev coreutils libevent-dev
ENV TERM=xterm \
    ZBX_TYPE=agent ZBX_OPT_TYPE=none

STOPSIGNAL SIGTERM

RUN addgroup zabbix && \
    adduser -S \
            -D -G zabbix \
            -h /var/lib/zabbix/ \
        zabbix && \
    mkdir -p /etc/zabbix && \
    mkdir -p /etc/zabbix/zabbix_agentd.d && \
    mkdir -p /var/lib/zabbix && \
    mkdir -p /var/lib/zabbix/enc && \
    mkdir -p /var/lib/zabbix/modules && \
    chown --quiet -R zabbix:root /var/lib/zabbix && \
    apk update && \
    apk add ${APK_FLAGS_PERSISTANT} \
            ${BUILD_PKGS} && \
    rm -rf /var/cache/apk/*

ARG MAJOR_VERSION=3.4
ARG ZBX_VERSION=${MAJOR_VERSION}.9
#ARG ZBX_SOURCES="https://sourceforge.net/projects/zabbix/files/ZABBIX%20Latest%20Stable/${ZBX_VERSION}/zabbix-${ZBX_VERSION}.tar.gz"
ARG ZBX_SOURCES="http://repo.zabbix.com/zabbix/3.4/ubuntu/pool/main/z/zabbix/zabbix_${ZBX_VERSION}.orig.tar.gz"
ENV ZBX_VERSION=${ZBX_VERSION} ZBX_SOURCES=${ZBX_SOURCES}

RUN apk add ${APK_FLAGS_DEV} --virtual build-dependencies \
            ${RUN_PKGS} \
    && cd /tmp/ \
    && curl -L ${ZBX_SOURCES} -o zabbix-${ZBX_VERSION}.tar.gz \
    && tar xf zabbix-${ZBX_VERSION}.tar.gz \
    && rm -rf zabbix-${ZBX_VERSION}.tar.gz \
    && cd /tmp/zabbix-${ZBX_VERSION} \
    && export CFLAGS="-fPIC -pie -Wl,-z,relro -Wl,-z,now" \
    && ./configure \
            --datadir=/usr/lib \
            --libdir=/usr/lib/zabbix \
            --prefix=/usr \
            --sysconfdir=/etc/zabbix \
            --prefix=/usr \
            --enable-agent \
            --enable-ipv6 \
            --silent \
    && make -j"$(nproc)" -s 1>/dev/null \
    && cp src/zabbix_agent/zabbix_agentd /usr/sbin/zabbix_agentd \
    && cp src/zabbix_get/zabbix_get /usr/bin/zabbix_get \
    && cp src/zabbix_sender/zabbix_sender /usr/bin/zabbix_sender \
    && cp conf/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf \
    && chown --quiet -R zabbix:root /etc/zabbix \
    && cd /tmp/ \
    &&rm -rf /tmp/zabbix-${ZBX_VERSION}/ \
    && apk del ${APK_FLAGS_COMMON} --purge \
            build-dependencies \
    && rm -rf /var/cache/apk/*

# service running
EXPOSE 10050/TCP
WORKDIR /var/lib/zabbix
VOLUME ["/etc/zabbix/zabbix_agentd.d", "/var/lib/zabbix/enc", "/var/lib/zabbix/modules"]
COPY ["docker-entrypoint.sh", "/usr/bin/"]
RUN chmod +x /usr/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]

