# docker-build

![](https://img.shields.io/github/commit-activity/y/kometchtech/docker-build.svg?style=popout-square)
![](https://img.shields.io/github/last-commit/kometchtech/docker-build.svg?style=popout-square)
![](https://img.shields.io/github/repo-size/kometchtech/docker-build.svg?style=popout-square)
[![GitHub repo size](https://img.shields.io/github/repo-size/kometchtech/docker-build.svg)](https://github.com/kometchtech/docker-build)

- personal docker build
- It exists to check the operation of container in the ARM environment (arm64/Aarch64).
  > For arm32, tackle depending on the mood. CI builds and publishes both `linux/amd64` and `linux/arm64`.
- Basically we will check the operation of the following application.
- Extensions are not necessarily build targets.
- Prioritize minimizing container size in build

## Build images

Docker is required; Buildx is needed for multi-platform images. Run from the
repository root. Each image directory contains a `Dockerfile` and a `VERSION`
file, and the version must be passed explicitly as a build argument:

```bash
docker build --build-arg VERSION="$(cat unbound/VERSION)" \
  -t kometchtech/unbound:$(cat unbound/VERSION) unbound
```

For a multi-architecture manifest:

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg VERSION="$(cat nsd/VERSION)" \
  -t kometchtech/nsd:$(cat nsd/VERSION) --push nsd
```

Only `pdnsrec` provides extra variants: use `-f pdnsrec/Dockerfile.alpha` with
`pdnsrec/VERSION.alpha`, or `-f pdnsrec/Dockerfile.beta` with
`pdnsrec/VERSION.beta`. Other `Dockerfile.*` files are local-only and have no
matching `VERSION.*`. CI refers to the default `Dockerfile` / `VERSION` pair as
the `stable` variant, tags stable images as `latest` and variants as `alpha` /
`beta`, publishes a multi-arch manifest to GHCR and syncs it to Docker Hub.

## base images

Current multi-arch bases include `debian:stable` / `debian:stable-slim`,
`debian:trixie` (BIND), `rust:slim` / `rust:latest`, `golang:latest` and
`gcr.io/distroless/static-debian13`. Bases pinned to `arm64v8/*` remain only
in local, git-ignored Dockerfiles.

## check software

| Software                         | url    | status   |
| -------------------------------- | ---|------------------------------------------------------ |
| hickory-dns | <https://github.com/hickory-dns/hickory-dns> | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/hickory-dns)![Docker Image Version](https://img.shields.io/docker/v/kometchtech/hickory-dns) ![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/hickory-dns) |
| NSD                              | <https://www.nlnetlabs.nl/projects/nsd/>               | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/nsd) ![Docker Image Version](https://img.shields.io/docker/v/kometchtech/nsd)      ![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/nsd) |
| Unbound                          | <https://www.nlnetlabs.nl/projects/unbound/>           | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/unbound) ![Docker Image Version](https://img.shields.io/docker/v/kometchtech/unbound)     ![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/unbound)|
| PowerDNS recursor                | <https://www.powerdns.com/recursor.html>               | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/pdnsrec)![Docker Image Version](https://img.shields.io/docker/v/kometchtech/pdnsrec)     ![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/pdnsrec)|
| Knot DNS resolver                | <https://www.knot-resolver.cz/>                        | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/kresd) ![Docker Image Version](https://img.shields.io/docker/v/kometchtech/kresd) ![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/kresd) |
| Knot DNS                         | <https://www.knot-dns.cz/>                             | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/knot)  ![Docker Image Version](https://img.shields.io/docker/v/kometchtech/knot)   ![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/knot) |
| CoreDNS                | <https://coredns.io/>                                  | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/coredns) ![Docker Image Version](https://img.shields.io/docker/v/kometchtech/coredns) ![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/coredns)  |
| dnsdist                          | <https://dnsdist.org/>                                 | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/dnsdist) ![Docker Image Version](https://img.shields.io/docker/v/kometchtech/dnsdist)    ![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/dnsdist) |
| BIND9                        | <https://www.isc.org/downloads/bind/>                  | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/bind) ![Docker Image Version](https://img.shields.io/docker/v/kometchtech/bind)                  ![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/bind)  |
| ISC Kea | <https://www.isc.org/kea/> | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/kea) ![Docker Image Version](https://img.shields.io/docker/v/kometchtech/kea) ![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/kea) |
| DNSCrypt Proxy                   | <https://github.com/jedisct1/dnscrypt-proxy>           | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/dnscrypt-proxy) ![Docker Image Version](https://img.shields.io/docker/v/kometchtech/dnscrypt-proxy)     ![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/dnscrypt-proxy)|
| Stubby                           | <https://github.com/getdnsapi/stubby>                  | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/stubby) ![Docker Image Version](https://img.shields.io/docker/v/kometchtech/stubby)                ![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/stubby)|

The table lists the images built by CI. Additional local directories (for
example `dibbler-server`, `glider`, `ipv6nat`, `isc_dhcp`, `stork-agent`,
`stork-server`, `zabbix-agent` and `zabbix-agent2`) are untracked and are not
built by CI.

## container registry

- Docker Hub <https://hub.docker.com/u/kometchtech/> (populated by the CI sync job)
- GitHub Container Registry (GHCR): `ghcr.io/kometchtech/<image>`
  <https://github.com/kometchtech?tab=packages>


## Tips

- configuration IPv6

```bash
echo '{"ipv6":true, "fixed-cidr-v6":"2001:db8:1::/64"}' | sudo tee -a /etc/docker/daemon.json
sudo systemctl restart docker.service
```

- If you make the Interface

```bash
docker network create --ipv6 \
    --gateway 2001:db8:1::1 \
    --subnet 2001:db8:1::/80 \
    docker-ipv6-network
```

