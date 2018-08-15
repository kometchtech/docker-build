# NSD: Name Server Daemon

[![](https://images.microbadger.com/badges/image/kometchtech/nsd.svg)](https://microbadger.com/images/kometchtech/nsd "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/kometchtech/nsd.svg)](https://microbadger.com/images/kometchtech/nsd "Get your own version badge on microbadger.com")
[![GitHub last commit](https://img.shields.io/github/last-commit/google/skia.svg)](https://github.com/kometchtech/docker-build/commits/master/nsd)

NSD: Name Server Daemon <https://www.nlnetlabs.nl/projects/nsd/>

## description

### Baseimage

arm64v8/alpine:edge

### minimum operating

```bash
docker run --rm -d -p 53:53/tcp -p 53:53/udp -v ${PWD}/nsd.conf:/usr/local/etc/nsd/nsd.conf -v ${PWD}/zones:/usr/local/etc/nsd/zones -v ${PWD}/db:/usr/local/var/db kometchtech/nsd:latest
```

### config

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

### document page

<https://www.nlnetlabs.nl/projects/nsd/nsd.conf.5.html>
