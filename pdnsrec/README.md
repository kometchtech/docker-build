# PowerDNS Recursor

![](https://img.shields.io/github/last-commit/kometchtech/docker-build.svg)
![](https://img.shields.io/docker/pulls/kometchtech/pdnsrec.svg)

[PowerDNS Recursor](https://www.powerdns.com/recursor.html) built from source. Multi-arch (amd64 / arm64).

## Image variants

| Tag | Dockerfile | Version file | Build system |
|---|---|---|---|
| `latest`, `<version>` | `Dockerfile` | `VERSION` | autoconf (`./configure`) |
| `alpha`, `<version>` | `Dockerfile.alpha` | `VERSION.alpha` | meson |
| `beta`, `<version>` | `Dockerfile.beta` | `VERSION.beta` | meson |

Recursor 5.5 pre-releases (alpha / beta) no longer ship `./configure` and are built with meson,
so they must not be built with the stable `Dockerfile`. Move the stable `Dockerfile` to meson
only once a stable release ships with meson.

## Base image

- Build stage: `rust:slim` (Recursor 5.x contains Rust code)
- Runtime stage: `debian:stable-slim`, with `tini` as init

## Build

From the repository root:

```bash
./build.py -d pdnsrec                          # stable (VERSION)
./build.py -f Dockerfile.alpha -d pdnsrec      # alpha  (VERSION.alpha)
./build.py -f Dockerfile.beta -d pdnsrec       # beta   (VERSION.beta)
```

`-f Dockerfile.<variant>` reads `VERSION.<variant>`. Do not use `-l` (local `latest` tag) for alpha / beta.

In CI (`.github/workflows/docker-build.yml`), changes to `Dockerfile[.alpha|.beta]` / `VERSION[.alpha|.beta]`
build the matching variant, and `workflow_dispatch` accepts `stable`, `alpha` or `beta`.

## Run

```bash
docker run -d --name pdnsrec \
  -p 53:53/udp -p 53:53/tcp -p 8082:8082 \
  -v /path/to/recursor.yml:/etc/powerdns/recursor.yml:ro \
  kometchtech/pdnsrec:latest
```

The default command is:

```bash
pdns_recursor --disable-syslog --log-timestamp=yes --config-dir=/etc/powerdns
```

This command is wrapped by `ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/sbin/entrypoint.sh"]`
(the same entrypoint is used in `Dockerfile.alpha` and `Dockerfile.beta`), so `tini` and the
entrypoint script run before `pdns_recursor`.

| Item | Value |
|---|---|
| Config directory | `/etc/powerdns` |
| Ports | `53/udp`, `53/tcp`, `8082` (web server) |
| User | `pdns-recursor` (group `pdns-rec`) |
| Data directories | `/var/lib/pdns-recursor`, `/var/run/pdns-recursor` |
| `TZ` | `Asia/Tokyo` |

## Documentation

<https://doc.powerdns.com/recursor/>
