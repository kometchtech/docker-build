# CoreDNS

[![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/coredns.svg)](https://hub.docker.com/r/kometchtech/coredns/)
[![Docker Version](https://img.shields.io/docker/v/kometchtech/coredns/latest.svg)](https://hub.docker.com/r/kometchtech/coredns/tags)
[![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/coredns/latest.svg)](https://hub.docker.com/r/kometchtech/coredns/)
[![GitHub last commit](https://img.shields.io/github/last-commit/kometchtech/docker-build.svg)](https://github.com/kometchtech/docker-build/commits/master/coredns)

[CoreDNS](https://coredns.io/) is a DNS server written in Go, built from source with multi-architecture support.

## Base images

- Build stage: `golang:latest`
- Runtime stage: `gcr.io/distroless/static-debian13`

The runtime image is the untagged `static-debian13` variant: the Dockerfile contains no `USER` instruction, so the container runs as the image's default user. It is not the `nonroot` tag, so do not assume UID 65532 or add `CAP_NET_BIND_SERVICE` for that reason.

The image version is taken from [`VERSION`](VERSION) and passed explicitly as the `VERSION` build argument.

## Build

From the repository root:

```sh
docker build --build-arg VERSION="$(cat coredns/VERSION)" \
  -t kometchtech/coredns:$(cat coredns/VERSION) coredns
```

## Run

```bash
docker run -d --name coredns \
  -p 53:53/tcp -p 53:53/udp \
  -p 443:443/tcp -p 443:443/udp \
  -v "$(pwd)/Corefile:/Corefile:ro" \
  kometchtech/coredns:latest
```

The entrypoint is `["/coredns"]`. Timezone (`TZ`) defaults to `Asia/Tokyo`.

## Exposed ports

| Port | Protocol | Description |
|---|---|---|
| `53` | TCP/UDP | DNS queries |
| `443` | TCP/UDP | Additional DNS listener (as configured in the `Corefile`) |

## Configuration

CoreDNS reads a `Corefile` from its working directory (mount it at `/Corefile` as above). Example:

```corefile
.:53 {
    forward . 8.8.8.8:53
    log
}
```

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `TZ` | `Asia/Tokyo` | Timezone setting |

## Documentation

<https://coredns.io/manual/toc/>
