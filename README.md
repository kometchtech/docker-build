# docker-build

![](https://img.shields.io/github/commit-activity/y/kometchtech/docker-build.svg?style=popout-square)
![](https://img.shields.io/github/last-commit/kometchtech/docker-build.svg?style=popout-square)
![](https://img.shields.io/github/repo-size/kometchtech/docker-build.svg?style=popout-square)
[![GitHub repo size in bytes](https://img.shields.io/github/repo-size/badges/shields.svg)](https://github.com/kometchtech/docker-build)

- personal docker build
- It exists to check the operation of container in the ARM environment (arm64/Aarch64).
  > For arm32, tackle depending on the mood.
- Basically we will check the operation of the following application.
- Extensions are not necessarily build targets.
- Prioritize minimizing container size in build

## base images

- [arm64v8/Debian:stable](https://hub.docker.com/r/arm64v8/debian/)
- [arm64v8/alpine](https://hub.docker.com/r/arm64v8/alpine/)

## check software

| Software                         | url                                                    | version                                                                                                                                                                                                                                                                                      |
| -------------------------------- | ------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| dibbler-server                   | <http://klub.com.pl/dhcpv6/>                           | [![](https://images.microbadger.com/badges/version/kometchtech/dibbler-server.svg)](https://microbadger.com/images/kometchtech/dibbler-server "Get your own version badge on microbadger.com")[![](https://images.microbadger.com/badges/image/kometchtech/dibbler-server.svg)](https://microbadger.com/images/kometchtech/dibbler-server "Get your own image badge on microbadger.com")![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/dibbler-server?style=flat-square)                                                                                               |
| NSD                              | <https://www.nlnetlabs.nl/projects/nsd/>               | [![](https://images.microbadger.com/badges/version/kometchtech/nsd.svg)](https://microbadger.com/images/kometchtech/nsd "Get your own version badge on microbadger.com")[![](https://images.microbadger.com/badges/image/kometchtech/nsd.svg)](https://microbadger.com/images/kometchtech/nsd "Get your own image badge on microbadger.com")![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/nsd?style=flat-square)                                                                                                                     |
| Unbound                          | <https://www.nlnetlabs.nl/projects/unbound/>           | [![](https://images.microbadger.com/badges/version/kometchtech/unbound.svg)](https://microbadger.com/images/kometchtech/unbound "Get your own version badge on microbadger.com")[![](https://images.microbadger.com/badges/image/kometchtech/unbound.svg)](https://microbadger.com/images/kometchtech/unbound "Get your own image badge on microbadger.com") ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/unbound?style=flat-square)                                                                                                            |
| PowerDNS recursor                | <https://www.powerdns.com/recursor.html>               | [![](https://images.microbadger.com/badges/version/kometchtech/pdnsrec.svg)](https://microbadger.com/images/kometchtech/pdnsrec "Get your own version badge on microbadger.com")[![](https://images.microbadger.com/badges/image/kometchtech/pdnsrec.svg)](https://microbadger.com/images/kometchtech/pdnsrec "Get your own image badge on microbadger.com") ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/pdnsrec)                                                                                                          |
| Knot DNS resolver                | <https://www.knot-resolver.cz/>                        | [![](https://images.microbadger.com/badges/version/kometchtech/kresd.svg)](https://microbadger.com/images/kometchtech/kresd "Get your own version badge on microbadger.com")[![](https://images.microbadger.com/badges/image/kometchtech/kresd.svg)](https://microbadger.com/images/kometchtech/kresd "Get your own image badge on microbadger.com") ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/kresd?style=flat-square)                                                                                                                |
| Knot DNS                         | <https://www.knot-dns.cz/>                             | [![](https://images.microbadger.com/badges/version/kometchtech/knot.svg)](https://microbadger.com/images/kometchtech/knot "Get your own version badge on microbadger.com")[![](https://images.microbadger.com/badges/image/kometchtech/knot.svg)](https://microbadger.com/images/kometchtech/knot "Get your own image badge on microbadger.com") ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/knot?style=flat-square)                                                                                                                  |
| CoreDNS (testing)                | <https://coredns.io/>                                  | Currently the Docker image is released from CoreDNS.io formula. <br> <https://hub.docker.com/r/coredns/coredns/> <br> [![](https://images.microbadger.com/badges/version/kometchtech/coredns.svg)](https://microbadger.com/images/kometchtech/coredns "Get your own version badge on microbadger.com")[![](https://images.microbadger.com/badges/image/kometchtech/coredns.svg)](https://microbadger.com/images/kometchtech/coredns "Get your own image badge on microbadger.com") ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/coredns?style=flat-square) |
| dnsdist                          | <https://dnsdist.org/>                                 | [![](https://images.microbadger.com/badges/version/kometchtech/dnsdist.svg)](https://microbadger.com/images/kometchtech/dnsdist "Get your own version badge on microbadger.com")[![](https://images.microbadger.com/badges/image/kometchtech/dnsdist.svg)](https://microbadger.com/images/kometchtech/dnsdist "Get your own image badge on microbadger.com") ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/dnsdist?style=flat-square)                                                                                                            |
| BIND9(testing)               | <https://www.isc.org/downloads/bind/>                  | [![](https://images.microbadger.com/badges/version/kometchtech/bind.svg)](https://microbadger.com/images/kometchtech/bind "Get your own version badge on microbadger.com")[![](https://images.microbadger.com/badges/image/kometchtech/bind.svg)](https://microbadger.com/images/kometchtech/bind "Get your own image badge on microbadger.com") ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/bind?style=flat-square)                                                                                                                  |
| ISC Kea | <https://www.isc.org/kea/> | [![](https://images.microbadger.com/badges/version/kometchtech/kea.svg)](https://microbadger.com/images/kometchtech/kea "Get your own version badge on microbadger.com")[![](https://images.microbadger.com/badges/image/kometchtech/kea.svg)](https://microbadger.com/images/kometchtech/kea "Get your own image badge on microbadger.com") ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/kea?style=flat-square)|
| zabbix-agent (testing)           | <https://www.zabbix.com/>                              | [![](https://images.microbadger.com/badges/version/kometchtech/zabbix-agent.svg)](https://microbadger.com/images/kometchtech/zabbix-agent "Get your own version badge on microbadger.com")[![](https://images.microbadger.com/badges/image/kometchtech/zabbix-agent.svg)](https://microbadger.com/images/kometchtech/zabbix-agent "Get your own image badge on microbadger.com") ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/zabbix-agent?style=flat-square)|
| mackerel-agent-plugins (testing) | <https://github.com/mackerelio/mackerel-agent-plugins> |made a deb package for armhf / arm64. <br> <https://github.com/kometchtech/mackerel-agent-plugins> |
| DNSCrypt Proxy                   | <https://github.com/jedisct1/dnscrypt-proxy>           | [![](https://images.microbadger.com/badges/version/kometchtech/dnscrypt-proxy.svg)](https://microbadger.com/images/kometchtech/dnscrypt-proxy "Get your own version badge on microbadger.com")[![](https://images.microbadger.com/badges/image/kometchtech/dnscrypt-proxy.svg)](https://microbadger.com/images/kometchtech/dnscrypt-proxy "Get your own image badge on microbadger.com") ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/dnscrypt-proxy?style=flat-square)                                                                                              |
| Stubby                           | <https://github.com/getdnsapi/stubby>                  | [![](https://images.microbadger.com/badges/version/kometchtech/stubby.svg)](https://microbadger.com/images/kometchtech/stubby "Get your own version badge on microbadger.com")[![](https://images.microbadger.com/badges/image/kometchtech/stubby.svg)](https://microbadger.com/images/kometchtech/stubby "Get your own image badge on microbadger.com") ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/stubby?style=flat-square)                                                                                                              |
| gobetween (testing)                       | <https://github.com/yyyar/gobetween>                   | [![](https://images.microbadger.com/badges/version/kometchtech/gobetween.svg)](https://microbadger.com/images/kometchtech/gobetween "Get your own version badge on microbadger.com")[![](https://images.microbadger.com/badges/image/kometchtech/gobetween.svg)](https://microbadger.com/images/kometchtech/gobetween "Get your own image badge on microbadger.com") ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/gobetween?style=flat-square)                                                                                                        |
| glider (testing)                          | <https://github.com/nadoo/glider>                      | [![](https://images.microbadger.com/badges/version/kometchtech/glider.svg)](https://microbadger.com/images/kometchtech/glider "Get your own version badge on microbadger.com")[![](https://images.microbadger.com/badges/image/kometchtech/glider.svg)](https://microbadger.com/images/kometchtech/glider "Get your own image badge on microbadger.com") ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/glider?style=flat-square)                                                                                                              |
| overture (testing) | <https://github.com/shawn1m/overture> | |


## container registry

- Docker hub <https://hub.docker.com/u/kometchtech/>
- GitHub Package Registry <https://github.com/kometchtech/docker-build/packages>


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

