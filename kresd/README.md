# Knot DNS Resolver

[![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/kresd.svg)](https://hub.docker.com/r/kometchtech/kresd)
[![Docker Image Version](https://img.shields.io/docker/v/kometchtech/kresd/latest?label=version)](https://hub.docker.com/r/kometchtech/kresd/tags)
[![Docker Image Size](https://img.shields.io/docker/image-size/kometchtech/kresd/latest)](https://hub.docker.com/r/kometchtech/kresd)
[![GitHub last commit](https://img.shields.io/github/last-commit/kometchtech/docker-build.svg)](https://github.com/kometchtech/docker-build/commits/master/kresd)

Knot Resolver <https://www.knot-resolver.cz/>

## Description

Knot Resolver is a caching full DNS resolver implementation. The image is a
multi-stage build that compiles the release from source and installs the
resulting Debian packages in a slim runtime image.

### Base image

- Build stage: `debian:stable`
- Runtime stage: `debian:stable-slim`

### Build

The release tag comes from `kresd/VERSION` (the `VERSION` build argument in the
Dockerfile). Run from the repository root:

```bash
./build.py -d kresd
```

### Run

```bash
docker run -d --name kresd \
  -p 53:53/udp -p 53:53/tcp \
  -p 443:443/tcp -p 853:853/tcp -p 5000:5000/tcp \
  -v /path/to/config.yaml:/etc/knot-resolver/config.yaml:ro \
  kometchtech/kresd:latest
```

The container runs:

```bash
/usr/bin/knot-resolver -c /etc/knot-resolver/config.yaml
```

`ENTRYPOINT` is `/usr/bin/knot-resolver` and `CMD` is
`-c /etc/knot-resolver/config.yaml`; pass arguments after the image name to
override the default command. The default configuration is copied from
`config.example.docker.yaml` in the Knot Resolver source tree. The image also
contains `/usr/local/bin/entrypoint.sh`, but it is not used as the container
entrypoint.

The build rewrites the resolver user and group from `knot-resolver` to `root`
so file and directory permission checks succeed. Lua configuration examples
that call `user('knot', 'knot')` therefore do not match this image.

### Docker Compose

```yaml
services:
  kresd:
    image: kometchtech/kresd:latest
    container_name: kresd
    restart: unless-stopped
    ports:
      - "53:53/udp"
      - "53:53/tcp"
      - "443:443/tcp"
      - "853:853/tcp"
      - "5000:5000/tcp"
    volumes:
      - ./config.yaml:/etc/knot-resolver/config.yaml:ro
      - kresd-cache:/var/cache/knot-resolver

volumes:
  kresd-cache:
```

### Paths and ports

| Item | Value |
|---|---|
| Configuration | `/etc/knot-resolver` (volume), default file `config.yaml` |
| Cache / trust anchors | `/var/cache/knot-resolver` (volume) |
| Exposed ports | `53/udp`, `53/tcp`, `443/tcp`, `853/tcp`, `5000/tcp` |

The image does not preset `TZ`; pass `-e TZ=Asia/Tokyo` (or another timezone) at
runtime if needed.

### Historical note

Early (2018) arm64 builds on Alpine hit a LuaJIT `bad light userdata pointer`
panic. The image is now built from Debian source packages; the old reports are
kept only for background: [issue #2](https://github.com/kometchtech/docker-build/issues/2),
[issue #7](https://github.com/kometchtech/docker-build/issues/7).

### Document page

<https://knot-resolver.readthedocs.io/en/stable/>
