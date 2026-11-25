# dnsdist

[![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/dnsdist.svg)](https://hub.docker.com/r/kometchtech/dnsdist)
[![Docker Image Version](https://img.shields.io/docker/v/kometchtech/dnsdist.svg)](https://hub.docker.com/r/kometchtech/dnsdist/tags)
[![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/dnsdist/latest)](https://hub.docker.com/r/kometchtech/dnsdist)
[![GitHub last commit](https://img.shields.io/github/last-commit/kometchtech/docker-build.svg)](https://github.com/kometchtech/docker-build/commits/master/dnsdist)

dnsdist <https://dnsdist.org/>

## description

dnsdist is a highly DNS-, DoS- and abuse-aware loadbalancer. Its goal in life is to route traffic to the best server, delivering top performance to legitimate users while shunting or blocking abusive traffic.

### Baseimage

- Common build stage: `rust:latest`
- Runtime stage: `debian:stable-slim`, with `tini` as init

The source release is downloaded from `downloads.powerdns.com` using the `VERSION`
build argument and compiled with meson. DoH, DoQ, DoH3, DoT, DNSCrypt, dnstap,
eBPF, SNMP and YAML support are enabled at build time, together with Cloudflare
`quiche`.

## Build

From the repository root:

```sh
docker build --build-arg VERSION="$(cat dnsdist/VERSION)" \
  -t kometchtech/dnsdist:$(cat dnsdist/VERSION) dnsdist
```

Pass the version from `VERSION` (currently `2.1.3`) as the `VERSION` build argument.

### minimum operating

```bash
docker run -d --name dnsdist \
  -p 53:53/udp -p 53:53/tcp -p 443:443/tcp -p 853:853/tcp \
  -v /path/to/dnsdist.yaml:/etc/dnsdist/dnsdist.yaml:ro \
  kometchtech/dnsdist:latest
```

### config

| Item | Value |
|---|---|
| Config directory | `/etc/dnsdist` |
| Working directory | `/etc/dnsdist` |
| Default command | `dnsdist --supervised --disable-syslog -u _dnsdist -g _dnsdist` |
| User / group | `_dnsdist` / `_dnsdist` |
| `TZ` | `Asia/Tokyo` |

The entrypoint (`/usr/local/bin/entrypoint.sh`, started via `tini`) executes any
arguments passed to it. If no arguments are supplied at all, it falls back to
`dnsdist --supervised --disable-syslog --log-timestamps -u _dnsdist -g _dnsdist --config /etc/dnsdist/dnsdist.yaml`.

### Exposed Ports

| Port | Protocol |
|---|---|
| `53` | TCP/UDP |
| `443` | TCP |
| `853` | TCP |
| `8083` | TCP |
| `8443` | TCP/UDP |

### Health check and signals

- `HEALTHCHECK CMD ["dnsdist", "-e", "showVersion()", "||", "exit", "1"]`
- `STOPSIGNAL SIGTERM`

### document page

<https://dnsdist.org/index_TOC.html>
