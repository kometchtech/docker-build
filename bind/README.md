# BIND DNS Server Docker Image

[![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/bind.svg)](https://hub.docker.com/r/kometchtech/bind)
[![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/bind/latest)](https://hub.docker.com/r/kometchtech/bind)

A Docker image for [ISC BIND](https://www.isc.org/bind/) DNS server, built from source with multi-architecture support.

## Supported Architectures

| Architecture | Tag |
|---|---|
| x86_64 (amd64) | `latest`, `9.x.x` |
| arm64 (aarch64) | `latest`, `9.x.x` |

## Features

- Built from source for optimized binary size
- Runs as non-root user (`_named`)
- Includes `tini` as init process
- Root hints (`named.ca`) pre-loaded
- Based on `debian:trixie-slim`

## Quick Start

```bash
docker run -d \
  --name bind \
  -p 53:53/tcp \
  -p 53:53/udp \
  -p 953:953/tcp \
  kometchtech/bind:latest
```

## Usage

### Using a custom `named.conf`

Mount your configuration file into the container:

```bash
docker run -d \
  --name bind \
  -p 53:53/tcp \
  -p 53:53/udp \
  -p 953:953/tcp \
  -v /path/to/your/named.conf:/etc/named/named.conf:ro \
  kometchtech/bind:latest
```

### Using Docker Compose

```yaml
services:
  bind:
    image: kometchtech/bind:latest
    container_name: bind
    restart: unless-stopped
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "953:953/tcp"
    volumes:
      - ./named.conf:/etc/named/named.conf:ro
      - ./zones:/var/cache/named/pri:ro
      - bind-cache:/var/cache/named
    environment:
      - TZ=Asia/Tokyo

volumes:
  bind-cache:
```

## Configuration

### Default Configuration

The default `named.conf` included in the image is configured as:

- **Recursion**: disabled
- **Allowed queries**: trusted networks only (`127.0.0.1`, `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `::1`)
- **Zone transfers**: disabled
- **Forwarders**: Cloudflare (`1.1.1.1`, `1.0.0.1`) and Google (`8.8.8.8`, `8.8.4.4`)

### Default ACL (trusted networks)

```
acl "trusted" {
    127.0.0.1;
    10.0.0.0/8;
    172.16.0.0/12;
    192.168.0.0/16;
    ::1;
};
```

### Important Paths

| Path | Description |
|---|---|
| `/etc/named/named.conf` | Main configuration file |
| `/var/cache/named/` | Cache and zone file directory |
| `/var/cache/named/named.ca` | Root hints file |
| `/var/cache/named/pri/` | Primary zone files directory |
| `/var/run/named/` | PID and session key directory |

## Exposed Ports

| Port | Protocol | Description |
|---|---|---|
| `53` | TCP/UDP | DNS query port |
| `953` | TCP | BIND control port (rndc) |

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `TZ` | `Asia/Tokyo` | Timezone setting |

## Security

- BIND runs as a dedicated non-root user `_named`
- Zone and config directories are restricted to `_named:_named` with `0750` permissions
- Zone transfers are disabled by default
- Recursive queries are disabled by default
