# PowerDNS Recursor

[![](https://images.microbadger.com/badges/image/kometchtech/pdnsrec.svg)](https://microbadger.com/images/kometchtech/pdnsrec "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/kometchtech/pdnsrec.svg)](https://microbadger.com/images/kometchtech/pdnsrec "Get your own version badge on microbadger.com")
![](https://img.shields.io/github/last-commit/kometchtech/docker-build.svg)
![](https://img.shields.io/docker/pulls/kometchtech/pdnsrec.svg)

PowerDNS Recursor <https://www.powerdns.com/recursor.html>

## description

### Baseimage

- [arm64v8/alpine](https://hub.docker.com/r/arm64v8/alpine/)

### info

As of August 5, 2018, `libressl` changed to `openssl` because it gets an error around encryption (ecdsa) during build.
As a result, `net-snmp-dev` is deleted because it becomes satisfies.

### minimum operating

```bash
/usr/local/sbin/pdns_recursor --log-timestamp=yes --daemon=no --write-pid=no --enable-syslog
```

### config

```config
```

### document page

<https://www.powerdns.com/documentation.html>
