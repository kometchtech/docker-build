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

Python 3 and Docker Buildx are required. Run from the repository root:

```bash
./build.py -d unbound
./build.py -d unbound -d nsd
./build.py -c -d unbound
./build.py -f Dockerfile.alpha -d pdnsrec
./build.py -f Dockerfile.beta -d pdnsrec
```

`build.py` is a local helper and is not committed to Git; a git-ignored legacy
`build.sh` may also exist in a local checkout but is not available in a fresh
clone. The default platform is `linux/amd64`; use `-p` to select platforms.
A single-platform build loads the image locally, while a comma-separated
multi-platform build pushes `kometchtech/<image>:<version>` to Docker Hub.
`-n` disables the cache, `-l` adds a local `latest` tag after a single-platform
build (ignored in check-only mode), and `-s` skips checks. Check failures are
warnings, including in check-only mode (`-c`). `-g` is accepted for
compatibility but does not perform Git operations.

`-f` selects a Dockerfile variant and reads the matching version file:
`Dockerfile.beta` uses `VERSION.beta`. Only `pdnsrec` currently provides
`Dockerfile.alpha` / `VERSION.alpha` and `Dockerfile.beta` / `VERSION.beta`;
CI refers to the default `Dockerfile` / `VERSION` pair as the `stable` variant.
Other `Dockerfile.*` files are local-only and have no matching `VERSION.*`.
Run `./build.py -h` for all options.

CI tags stable images as `latest` and variants as `alpha` / `beta`.

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

