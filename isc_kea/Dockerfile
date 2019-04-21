# syntax = docker/dockerfile:experimental
FROM arm64v8/alpine:edge AS build
ARG PKGS="kea@testing kea-dhcp4@testing kea-dhcp6@testing kea-keactrl@testing kea-utils@testing kea-admin@testing "

RUN echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk add --update --no-cache ${PKGS}

WORKDIR /etc/kea
CMD ["keactrl", "start"]
