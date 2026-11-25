# Stubby

[![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/stubby.svg)](https://hub.docker.com/r/kometchtech/stubby)
[![Docker Image Version](https://img.shields.io/docker/v/kometchtech/stubby/latest?label=version)](https://hub.docker.com/r/kometchtech/stubby/tags)
[![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/stubby/latest)](https://hub.docker.com/r/kometchtech/stubby)
[![GitHub last commit](https://img.shields.io/github/last-commit/kometchtech/docker-build.svg)](https://github.com/kometchtech/docker-build/commits/master/stubby)

- DNS Privacy Daemon - Stubby <https://github.com/getdnsapi/stubby>
- A modern asynchronous DNS API <https://getdnsapi.net/>
- docker-getdns-stubby <https://github.com/juzam/docker-getdns-stubby>

## Description

Stubby is a mode of `getdns` that acts as a local DNS Privacy stub resolver
using DNS-over-TLS. getdns and Stubby are both compiled from source in this
multi-stage image.

### Base image

- Build stages: `debian:stable` (`base-build`, `getdns-build`, `stubby-build`)
- Runtime stage: `debian:stable-slim`

### Build

The Stubby release tag comes from `stubby/VERSION` (the `VERSION` build argument
in the Dockerfile). getdns is cloned and built from source in an earlier stage.
Run from the repository root:

```sh
docker build --build-arg VERSION="$(cat stubby/VERSION)" \
  -t kometchtech/stubby:$(cat stubby/VERSION) stubby
```

### Run

```bash
docker run -d --name stubby \
  -p 53:53/udp -p 53:53/tcp \
  -v /path/to/stubby.yml:/etc/stubby/stubby.yml:ro \
  kometchtech/stubby:latest
```

The container starts via `tini` and runs:

```bash
/usr/local/bin/stubby -l
```

The entrypoint is `/usr/bin/tini -- /usr/local/bin/entrypoint.sh`; the script
executes the command passed to it, so the default `CMD` can be overridden at
runtime.

### Config

The default configuration is copied from `stubby.yml.example` to
`/etc/stubby/stubby.yml` during the build. The working directory is
`/etc/stubby`.

### Paths, ports and environment

| Item | Value |
|---|---|
| Configuration | `/etc/stubby/stubby.yml` |
| Exposed ports | `53/udp`, `53/tcp` |
| Stop signal | `SIGTERM` |
| `TZ` | `Asia/Tokyo` (override with `-e TZ=...`) |

### Document page

<https://dnsprivacy.org/wiki/display/DP/DNS+Privacy+Daemon+-+Stubby>
