# knot DNS

[![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/knot.svg)](https://hub.docker.com/r/kometchtech/knot)
[![Docker Image Version](https://img.shields.io/docker/v/kometchtech/knot.svg)](https://hub.docker.com/r/kometchtech/knot/tags)
[![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/knot/latest)](https://hub.docker.com/r/kometchtech/knot)
[![GitHub last commit](https://img.shields.io/github/last-commit/kometchtech/docker-build.svg)](https://github.com/kometchtech/docker-build/commits/master/knot)

<https://www.knot-dns.cz/>

## description

Knot DNS is a high-performance authoritative-only DNS server which supports all key features of the modern domain name system.

## Baseimage

- Build stage: `debian:stable`
- Runtime stage: `debian:stable-slim`, with `tini` as init

Knot DNS is compiled from source with QUIC and dnstap support; documentation and
systemd integration are disabled.

## Build

From the repository root:

```bash
./build.py -d knot
```

`build.py` passes the version from `VERSION` (currently `3.6.2`) to the Dockerfile.
Building the Dockerfile directly without that argument uses its `ARG VERSION` default.

## Quick Start

```bash
docker run -d --name knot \
  -p 53:53/udp -p 53:53/tcp -p 853:853/tcp \
  -v /path/to/knot.conf:/etc/knot/knot.conf:ro \
  kometchtech/knot:latest
```

## config

| Item | Value |
|---|---|
| Config directory | `/etc/knot` |
| Config file | `/etc/knot/knot.conf` |
| Sample config | `/etc/knot-dns/knot.sample.conf` |
| Working directory | `/etc/knot-dns` |
| Data / run directories | `/var/lib/knot`, `/run/knot` |
| `TZ` | `Asia/Tokyo` |

On startup, `/usr/local/sbin/entrypoint.sh` (launched via `tini`) creates the
necessary directories, removes stale pid/socket files and initializes the
configuration database if needed. When no `/etc/knot/knot.conf` exists, it copies
the sample config there, sets the user to `root:root`, changes `listen` to all
interfaces and sends logs to stdout. It then checks the configuration with
`knotc -c /etc/knot/knot.conf conf-check` and starts
`knotd -c /etc/knot/knot.conf -v` with any extra arguments.

## Exposed Ports

| Port | Protocol |
|---|---|
| `53` | UDP/TCP |
| `853` | TCP |

## Signals

- `STOPSIGNAL SIGTERM`
- `ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/sbin/entrypoint.sh"]`
