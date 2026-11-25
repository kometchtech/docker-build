# Unbound

[![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/unbound.svg)](https://hub.docker.com/r/kometchtech/unbound/)
[![Docker Version](https://img.shields.io/docker/v/kometchtech/unbound/latest.svg)](https://hub.docker.com/r/kometchtech/unbound/tags)
[![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/unbound/latest.svg)](https://hub.docker.com/r/kometchtech/unbound/)
[![GitHub last commit](https://img.shields.io/github/last-commit/kometchtech/docker-build.svg)](https://github.com/kometchtech/docker-build/commits/master/unbound)

[Unbound](https://www.nlnetlabs.nl/projects/unbound/) is a validating, recursive, caching DNS resolver, built from source with multi-architecture support.

## Base images

- Build stage: `debian:stable`
- Runtime stage: `debian:stable-slim`

The image version is taken from [`VERSION`](VERSION) and passed as the `VERSION` build argument by `build.py`.

## Features

- Runs as a dedicated, unprivileged `unbound` user/group
- Entrypoint `/usr/local/sbin/entrypoint.sh` prepares `unbound-control` keys, `root.key` (via `unbound-anchor`) and `named.root` before starting the daemon
- Default command: `unbound -d -c /etc/unbound/unbound.conf`
- Healthcheck: `unbound-control status` every 30s (30s timeout, 5s start period, 3 retries)
- Timezone (`TZ`) defaults to `Asia/Tokyo`
- Working directory: `/etc/unbound`

## Build

From the repository root:

```sh
./build.py -d unbound
```

## Run

```bash
docker run -d --name unbound \
  -p 53:53/tcp -p 53:53/udp -p 853:853/tcp \
  -v /path/to/unbound.conf:/etc/unbound/unbound.conf:ro \
  kometchtech/unbound:latest
```

## Exposed ports

| Port | Protocol | Description |
|---|---|---|
| `53` | TCP/UDP | DNS queries |
| `853` | TCP | DNS over TLS |

## Configuration

Mount your configuration at `/etc/unbound/unbound.conf`; the entrypoint creates the control certificates and root trust anchor in `/etc/unbound` on first start. The runtime directories `/etc/unbound`, `/var/run/unbound` and `/var/lib/unbound` are owned by `unbound:unbound`.

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `TZ` | `Asia/Tokyo` | Timezone setting |

## Documentation

<https://www.unbound.net/documentation/index.html>
