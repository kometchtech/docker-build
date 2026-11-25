# syntax = docker/dockerfile:experimental
ARG ALPINE_VERSION=latest

# Build stage
FROM alpine:${ALPINE_VERSION} AS builder
ARG VERSION
ARG ZBX_SOURCES=https://git.zabbix.com/scm/zbx/zabbix.git

# Install build dependencies
RUN set -eux && \
    apk add --no-cache --virtual .build-deps autoconf automake g++ git make pcre-dev zlib-dev openssl-dev coreutils go linux-headers

RUN set -eux && \
    cd /tmp/ && \
    # Clone specific tag based on VERSION
    git clone ${ZBX_SOURCES} --branch ${VERSION} --depth 1 --single-branch zabbix-${VERSION} && \
    cd /tmp/zabbix-${VERSION} && \
    zabbix_revision=`git rev-parse --short HEAD` && \
    sed -i "s/{ZABBIX_REVISION}/$zabbix_revision/g" src/go/pkg/version/version.go && \
    ./bootstrap.sh && \
    export CFLAGS="-fPIC -pie -Wl,-z,relro -Wl,-z,now" && \
    export GOPATH=/tmp/zabbix-${VERSION}/go && \
    # Configure and build
    ./configure \
        --datadir=/usr/lib \
        --libdir=/usr/lib/zabbix \
        --prefix=/usr \
        --sysconfdir=/etc/zabbix \
        --enable-ipv6 \
        --enable-agent2 \
        --enable-agent \
        --with-openssl \
        --silent && \
    make -j"$(nproc)" -s && \
    # Prepare files for the final image
    mkdir -p /tmp/zabbix-install/usr/sbin && \
    mkdir -p /tmp/zabbix-install/usr/bin && \
    mkdir -p /tmp/zabbix-install/etc/zabbix && \
    cp /tmp/zabbix-${VERSION}/src/go/bin/zabbix_agent2 /tmp/zabbix-install/usr/sbin/zabbix_agent2 && \
    cp /tmp/zabbix-${VERSION}/src/zabbix_get/zabbix_get /tmp/zabbix-install/usr/bin/zabbix_get && \
    cp /tmp/zabbix-${VERSION}/src/zabbix_sender/zabbix_sender /tmp/zabbix-install/usr/bin/zabbix_sender && \
    cp /tmp/zabbix-${VERSION}/src/go/conf/zabbix_agent2.conf /tmp/zabbix-install/etc/zabbix/zabbix_agent2.conf

# Final image
FROM alpine:${ALPINE_VERSION}

ARG MAJOR_VERSION
ARG VERSION
ARG ZBX_SOURCES

ENV TERM=xterm 

# Create Zabbix user and directories
RUN set -eux && \
    addgroup -S -g 1000 zabbix && \
    adduser -S \
            -D -G zabbix \
            -u 999 \
            -h /var/lib/zabbix/ \
        zabbix && \
    mkdir -p /etc/zabbix && \
    mkdir -p /etc/zabbix/zabbix_agentd.d && \
    mkdir -p /var/lib/zabbix && \
    mkdir -p /var/lib/zabbix/enc && \
    mkdir -p /var/lib/zabbix/modules && \
    chown --quiet -R zabbix:root /var/lib/zabbix && \
    # Install runtime dependencies only
    apk add --no-cache --clean-protected tini bash pcre openssl coreutils iputils && \
    rm -rf /var/cache/apk/*

# Copy built binaries and config from builder stage
COPY --from=builder /tmp/zabbix-install/usr/sbin/zabbix_agent2 /usr/sbin/
COPY --from=builder /tmp/zabbix-install/usr/bin/zabbix_get /usr/bin/
COPY --from=builder /tmp/zabbix-install/usr/bin/zabbix_sender /usr/bin/
COPY --from=builder /tmp/zabbix-install/etc/zabbix/zabbix_agent2.conf /etc/zabbix/

# Configure permissions
RUN chown -R zabbix:zabbix /etc/zabbix/

EXPOSE 10050/TCP

STOPSIGNAL SIGTERM

WORKDIR /var/lib/zabbix

VOLUME ["/var/lib/zabbix/enc"]

COPY ["entrypoint.sh", "/usr/bin/"]
RUN chmod +x /usr/bin/entrypoint.sh

ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/entrypoint.sh"]

USER zabbix

CMD ["/usr/sbin/zabbix_agent2", "--foreground", "-c", "/etc/zabbix/zabbix_agent2.conf"]

# Labels at the end to reduce the impact on multi-stage builds
LABEL org.opencontainers.image.title="Zabbix agent 2" \
      org.opencontainers.image.authors="kometchtech <kometch@gmail.com>" \
      org.opencontainers.image.url="https://zabbix.com/" \
      org.opencontainers.image.description="Zabbix agent 2 is deployed on a monitoring target to actively monitor local resources and applications" \
      org.opencontainers.image.licenses="GPL v2.0" \
      org.opencontainers.image.documentation="https://www.zabbix.com/documentation/${MAJOR_VERSION}/manual/installation/containers" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.source="${ZBX_SOURCES}"
