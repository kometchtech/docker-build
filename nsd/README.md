# NSD: Name Server Daemon

[![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/nsd.svg)](https://hub.docker.com/r/kometchtech/nsd)
[![Docker Image Version](https://img.shields.io/docker/v/kometchtech/nsd/latest?label=version)](https://hub.docker.com/r/kometchtech/nsd/tags)
[![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/nsd/latest)](https://hub.docker.com/r/kometchtech/nsd)
[![GitHub last commit](https://img.shields.io/github/last-commit/kometchtech/docker-build.svg)](https://github.com/kometchtech/docker-build/commits/master/nsd)

NSD: Name Server Daemon <https://www.nlnetlabs.nl/projects/nsd/>

## Description

NSD is an authoritative DNS server, compiled from source in this image.

### Base image

Multi-stage build:

- Build stage: `debian:stable` (common build base + NSD build stage)
- Runtime stage: `debian:stable-slim`

### Build

The release tag comes from `nsd/VERSION` (the `VERSION` build argument in the
Dockerfile). Run from the repository root:

```bash
./build.py -d nsd
```

### Run

```bash
docker run -d --name nsd \
  -p 53:53/tcp -p 53:53/udp -p 8952:8952/tcp \
  -v /path/to/nsd.conf:/etc/nsd/nsd.conf:ro \
  -v /path/to/zones:/etc/nsd/zones \
  -v /path/to/cache:/var/cache/nsd \
  kometchtech/nsd:latest
```

The default configuration at `/etc/nsd/nsd.conf` is copied from
`nsd.conf.sample` during the build. The container starts via `tini` and runs:

```bash
nsd -d -c /etc/nsd/nsd.conf
```

The entrypoint (`/usr/bin/tini -- /usr/local/sbin/entrypoint.sh`) fixes up
ownership of `/var/cache/nsd`, `/var/run/nsd` and `/etc/nsd/zones` when running
as root, prepares `/var/cache/nsd/nsd-xfr`, and then executes the given
command. NSD itself runs as the `nsd` user configured at build time.

### Paths and ports

| Item | Value |
|---|---|
| Configuration | `/etc/nsd/nsd.conf` |
| Zone files | `/etc/nsd/zones` |
| Database / XFR state | `/var/cache/nsd/zone.db`, `/var/cache/nsd/xfrd.state` |
| Exposed ports | `53/tcp`, `53/udp`, `8952/tcp` |
| Stop signal | `SIGTERM` |
| User | `nsd` |

The default timezone is `Asia/Tokyo` (`TZ`); override it with `-e TZ=...` if
needed.

### Config

```conf
server:
    server-count: 1
    verbosity: 1
    database: ""
    hide-version: yes
    round-robin: yes

# primary
zone:
    name: "example.local"
    zonefile: example.local.db
    allow-notify: <secondary-ip> NOKEY
    provide-xfr: <secondary-ip> NOKEY
    notify-retry: 5

# secondary
zone:
    name: "example.local"
    zonefile: example.local.db
    allow-notify: <primary-ip> NOKEY
    request-xfr: AXFR <primary-ip> NOKEY
    allow-axfr-fallback: yes
```

### Document page

<https://www.nlnetlabs.nl/projects/nsd/nsd.conf.5.html>
