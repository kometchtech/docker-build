# CoreDNS

CoreDNS <https://coredns.io/>

## description

[![](https://images.microbadger.com/badges/image/kometchtech/coredns:20181112.svg)](https://microbadger.com/images/kometchtech/coredns:20181112 "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/kometchtech/coredns:20181112.svg)](https://microbadger.com/images/kometchtech/coredns:20181112 "Get your own version badge on microbadger.com")
[![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/coredns.svg)](https://hub.docker.com/r/kometchtech/coredns/)

## !Announce!

As the Arm64 image is released from the official, it will not be updated here.

- [coredns/coredns](https://hub.docker.com/r/coredns/coredns/)  
 - tag: coredns-arm64

### Baseimage

- arm64v8/alpine:latest

### Baseimage

- `gcr.io/distroless/static-debian13`

> **Note:** distroless イメージは `nonroot` ユーザー (UID 65532) で実行されます。
> ポート 53 などの特権ポート (< 1024) にバインドするには、コンテナ起動時に
> `CAP_NET_BIND_SERVICE` ケーパビリティの付与が必要です。

### minimum operating

```bash
docker run --rm -d \
  --cap-add=NET_BIND_SERVICE \
  -p 53:53/tcp -p 53:53/udp \
  -v ${PWD}:/etc/coredns/corefile \
  kometchtech/coredns
```

### config

```cady
.:53 {
    forward . 8.8.8.8:53
    log
}
```

### document page

<https://coredns.io/manual/toc/>
