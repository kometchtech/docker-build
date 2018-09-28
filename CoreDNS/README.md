# CoreDNS

CoreDNS <https://coredns.io/>

## description

## !Announce!

As the Arm64 image is released from the official, it will not be updated here.

- [coredns/coredns](https://hub.docker.com/r/coredns/coredns/)  
 - tag: coredns-arm64

### Baseimage

- arm64v8/alpine:latest

### minimum operating

```bash
docker run --rm -d -p 53:53/tcp -p 53:53/udp -v ${PWD}:/etc/coredns/corefile kometchtech/coredns
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
