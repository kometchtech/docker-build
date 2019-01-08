# docker-build

[![GitHub commit activity the past week, 4 weeks, year](https://img.shields.io/github/commit-activity/y/eslint/eslint.svg)](https://github.com/kometchtech/docker-build/commits/master)
[![GitHub last commit](https://img.shields.io/github/last-commit/google/skia.svg)](https://github.com/kometchtech/docker-build/commits/master)
[![GitHub repo size in bytes](https://img.shields.io/github/repo-size/badges/shields.svg)](https://github.com/kometchtech/docker-build)

personal docker build

It exists to check the operation of container in the ARM environment (arm64/Aarch64).
> For arm32, tackle depending on the mood.

Basically we will check the operation of the following application.

## base images

- Debian stretch/testing
- [arm64v8/alpine](https://hub.docker.com/r/arm64v8/alpine/)

## check software

| Software                         | url                                                    | version                                                                                                                                                                                                                                                                                      |
| -------------------------------- | ------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| dibbler-server                   | <http://klub.com.pl/dhcpv6/>                           | [![](https://images.microbadger.com/badges/version/kometchtech/dibbler-server.svg)](https://microbadger.com/images/kometchtech/dibbler-server "Get your own version badge on microbadger.com")                                                                                               |
| NSD                              | <https://www.nlnetlabs.nl/projects/nsd/>               | [![](https://images.microbadger.com/badges/version/kometchtech/nsd.svg)](https://microbadger.com/images/kometchtech/nsd "Get your own version badge on microbadger.com")                                                                                                                     |
| Unbound                          | <https://www.nlnetlabs.nl/projects/unbound/>           | [![](https://images.microbadger.com/badges/version/kometchtech/unbound.svg)](https://microbadger.com/images/kometchtech/unbound "Get your own version badge on microbadger.com")                                                                                                             |
| PowerDNS recursor                | <https://www.powerdns.com/recursor.html>               | [![](https://images.microbadger.com/badges/version/kometchtech/pdns_rec.svg)](https://microbadger.com/images/kometchtech/pdns_rec "Get your own version badge on microbadger.com")                                                                                                           |
| Knot DNS resolver                | <https://www.knot-resolver.cz/>                        | [![](https://images.microbadger.com/badges/version/kometchtech/kresd.svg)](https://microbadger.com/images/kometchtech/kresd "Get your own version badge on microbadger.com")                                                                                                                 |
| Knot DNS                         | <https://www.knot-dns.cz/>                             | [![](https://images.microbadger.com/badges/version/kometchtech/knot.svg)](https://microbadger.com/images/kometchtech/knot "Get your own version badge on microbadger.com")                                                                                                                   |
| CoreDNS (testing)                | <https://coredns.io/>                                  | Currently the Docker image is released from CoreDNS.io formula. <https://hub.docker.com/r/coredns/coredns/> [![](https://images.microbadger.com/badges/version/kometchtech/coredns.svg)](https://microbadger.com/images/kometchtech/coredns "Get your own version badge on microbadger.com") |
| dnsdist                          | <https://dnsdist.org/>                                 | [![](https://images.microbadger.com/badges/version/kometchtech/dnsdist.svg)](https://microbadger.com/images/kometchtech/dnsdist "Get your own version badge on microbadger.com")                                                                                                             |
| BIND9.13 (testing)               | <https://www.isc.org/downloads/bind/>                  | [![](https://images.microbadger.com/badges/version/kometchtech/bind.svg)](https://microbadger.com/images/kometchtech/bind "Get your own version badge on microbadger.com")                                                                                                                   |
| zabbix-agent (testing)           | <https://www.zabbix.com/>                              | [![](https://images.microbadger.com/badges/version/kometchtech/zabbix-agent.svg)](https://microbadger.com/images/kometchtech/zabbix-agent "Get your own version badge on microbadger.com") |
| mackerel-agent-plugins (testing) | <https://github.com/mackerelio/mackerel-agent-plugins> |made a deb package for armhf / arm64.
<https://github.com/kometchtech/mackerel-agent-plugins>|
| DNSCrypt Proxy                   | <https://github.com/jedisct1/dnscrypt-proxy>           | [![](https://images.microbadger.com/badges/version/kometchtech/dnscrypt-proxy.svg)](https://microbadger.com/images/kometchtech/dnscrypt-proxy "Get your own version badge on microbadger.com")                                                                                               |
| Stubby                           | <https://github.com/getdnsapi/stubby>                  | [![](https://images.microbadger.com/badges/version/kometchtech/stubby.svg)](https://microbadger.com/images/kometchtech/stubby "Get your own version badge on microbadger.com")                                                                                                               |
| gobetween                        | <https://github.com/yyyar/gobetween>                   | [![](https://images.microbadger.com/badges/version/kometchtech/gobetween.svg)](https://microbadger.com/images/kometchtech/gobetween "Get your own version badge on microbadger.com")                                                                                                         |
| glider                           | <https://github.com/nadoo/glider>                      | [![](https://images.microbadger.com/badges/version/kometchtech/glider.svg)](https://microbadger.com/images/kometchtech/glider "Get your own version badge on microbadger.com")                                                                                                               |
| overture | <https://github.com/shawn1m/overture> | |

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

