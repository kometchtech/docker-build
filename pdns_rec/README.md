# PowerDNS Recursor

[![](https://images.microbadger.com/badges/image/kometchtech/pdns_rec.svg)](https://microbadger.com/images/kometchtech/pdns_rec "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/kometchtech/pdns_rec.svg)](https://microbadger.com/images/kometchtech/pdns_rec "Get your own version badge on microbadger.com")
[![GitHub last commit](https://img.shields.io/github/last-commit/google/skia.svg)](https://github.com/kometchtech/docker-build/commits/master/pdns_rec)

PowerDNS Recursor <https://www.powerdns.com/recursor.html>

## description

### Baseimage

arm64v8/alpine:latest

### info

As of August 5, 2018, `libressl` changed to `openssl` because it gets an error around encryption (ecdsa) during build.   
As a result, `net-snmp-dev` is deleted because it becomes satisfies.

### minimum operating

### config

### document page

<https://www.powerdns.com/documentation.html>
