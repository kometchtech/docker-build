# dnscrypt-proxy

[![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/dnscrypt-proxy.svg)](https://hub.docker.com/r/kometchtech/dnscrypt-proxy)
[![Docker Image Version](https://img.shields.io/docker/v/kometchtech/dnscrypt-proxy.svg)](https://hub.docker.com/r/kometchtech/dnscrypt-proxy/tags)
[![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/dnscrypt-proxy/latest)](https://hub.docker.com/r/kometchtech/dnscrypt-proxy)
[![GitHub last commit](https://img.shields.io/github/last-commit/kometchtech/docker-build.svg)](https://github.com/kometchtech/docker-build/commits/master/dnscrypt-proxy)

<https://github.com/jedisct1/dnscrypt-proxy>

## description

dnscrypt-proxy 2 - A flexible DNS proxy, with support for encrypted DNS protocols. <https://dnscrypt.info>

## Base image

- Build stage: `golang:alpine` (with `git` and `tzdata` installed)
- Runtime stage: `gcr.io/distroless/static-debian13`

The binary is built statically (`CGO_ENABLED=0`, `osusergo netgo` tags) from the
source tag given by the `VERSION` build argument, then copied into the distroless
runtime image.

## Build

From the repository root:

```bash
./build.py -d dnscrypt-proxy
```

`build.py` passes the version from `VERSION` (currently `2.2.21`) to the Dockerfile.
Git and `tzdata` are installed only in the builder stage.

## Quick Start

```bash
docker run -d --name dnscrypt-proxy \
  -p 53:53/tcp -p 53:53/udp \
  kometchtech/dnscrypt-proxy:latest
```

The image includes the `example-*` configuration files from the upstream source
under `/etc/dnscrypt-proxy/`. Mount your own configuration over them for real use:

```bash
docker run -d --name dnscrypt-proxy \
  -p 53:53/tcp -p 53:53/udp \
  -v /path/to/dnscrypt-proxy.toml:/etc/dnscrypt-proxy/example-dnscrypt-proxy.toml:ro \
  kometchtech/dnscrypt-proxy:latest
```

## Configuration and runtime

| Item | Value |
|---|---|
| Config directory | `/etc/dnscrypt-proxy/` (`example-*` files from upstream) |
| Working directory | `/etc/dnscrypt-proxy/` |
| Binary | `/dnscrypt-proxy` |
| Default command | `/dnscrypt-proxy -config /etc/dnscrypt-proxy/example-dnscrypt-proxy.toml` |
| `PATH` | `/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin` |
| `TZ` | `Asia/Tokyo` |

## Exposed Ports

| Port | Protocol |
|---|---|
| `53` | TCP/UDP |
