# CoreDNS

CoreDNS <https://coredns.io/>

## description

### Baseimage

arm64v8/Alpine

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