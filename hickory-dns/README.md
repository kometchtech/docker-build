# Hickory DNS

[![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/hickory-dns.svg)](https://hub.docker.com/r/kometchtech/hickory-dns/)
[![Docker Version](https://img.shields.io/docker/v/kometchtech/hickory-dns/latest.svg)](https://hub.docker.com/r/kometchtech/hickory-dns/tags)
[![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/hickory-dns/latest.svg)](https://hub.docker.com/r/kometchtech/hickory-dns/)
[![GitHub last commit](https://img.shields.io/github/last-commit/kometchtech/docker-build.svg)](https://github.com/kometchtech/docker-build/commits/master/hickory-dns)

[Hickory DNS](https://github.com/hickory-dns/hickory-dns) is a DNS server, client and resolver written in Rust. This image builds the `hickory-dns` server binary from the upstream source release.

## Base images

- Build stage: `rust:latest` (selected with `--platform=$TARGETPLATFORM`)
- Runtime stage: `debian:stable-slim`, with `libssl3` and `ca-certificates`

The binary is copied to `/usr/bin/hickory-dns` and checked with `hickory-dns --version` during the build. The runtime stage sets `USER nobody:nobody`; no timezone is preset and no configuration files are included.

## Build

The release tag comes from [`VERSION`](VERSION) and is passed as the `VERSION` build argument. Run from the repository root:

```bash
./build.py -d hickory-dns
```

The source archive is downloaded from `https://github.com/hickory-dns/hickory-dns/archive/refs/tags/v${VERSION}.tar.gz`. The build uses `cargo build --release --no-default-features --features $FEATURES`; the `FEATURES` argument in the Dockerfile enables the TLS / HTTPS / QUIC / H3 providers (both `aws-lc-rs` and `ring`), `serde` and the `DEFAULT_FEATURES` set (`ascii-art`, `resolver`, `rustls-platform-verifier`, `sqlite`). The Dockerfile's own `ARG VERSION` default is only a fallback when no build argument is supplied.

## Run

The entrypoint is `hickory-dns` and there is no default `CMD`, so a configuration file must be supplied as an argument:

```bash
docker run -d --name hickory-dns \
  -p 53:53/tcp -p 53:53/udp \
  -v /path/to/named.toml:/etc/named.toml:ro \
  -v /path/to/zones:/var/named:ro \
  kometchtech/hickory-dns:latest \
  --config /etc/named.toml --zonedir /var/named
```

The Dockerfile declares no `EXPOSE` instructions, so publish the listener ports explicitly with `-p`. Encrypted transports (for example TLS on 853 and HTTPS on 443) must be enabled in `named.toml`. Because the container runs as `nobody:nobody`, binding to a privileged port such as 53 requires `CAP_NET_BIND_SERVICE` (or use a non-privileged container port and map it to a privileged host port).

| Item | Value |
|---|---|
| Entrypoint | `hickory-dns` (no default arguments) |
| Configuration | `/etc/named.toml` (mount your own; none is bundled) |
| Zone directory | `/var/named` (mount your own; none is bundled) |
| User | `nobody:nobody` |
| Binary | `/usr/bin/hickory-dns` |
| Exposed ports | None declared in the Dockerfile; publish the ports configured in `named.toml` |

## Documentation

- Configuration: <https://hickory-dns.org/config/>
- Upstream repository: <https://github.com/hickory-dns/hickory-dns>
