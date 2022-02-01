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
| NSD                              | <https://www.nlnetlabs.nl/projects/nsd/>               | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/nsd) ![Docker Image Version (latest semver)](https://img.shields.io/docker/v/kometchtech/nsd?sort=semver)     |
| Unbound                          | <https://www.nlnetlabs.nl/projects/unbound/>           | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/unbound) ![Docker Image Version (latest semver)](https://img.shields.io/docker/v/kometchtech/unbound?sort=semver)    |
| PowerDNS recursor                | <https://www.powerdns.com/recursor.html>               | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/pdnsrec) ![Docker Image Version (latest semver)](https://img.shields.io/docker/v/kometchtech/pdnsrec?sort=semver)    |
| Knot DNS resolver                | <https://www.knot-resolver.cz/>                        | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/kresd) ![Docker Image Version (latest semver)](https://img.shields.io/docker/v/kometchtech/kresd?sort=semver)|
| Knot DNS                         | <https://www.knot-dns.cz/>                             | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/knot)  ![Docker Image Version (latest semver)](https://img.shields.io/docker/v/kometchtech/knot?sort=semver)  |
| CoreDNS (testing)                | <https://coredns.io/>                                  | Currently the Docker image is released from CoreDNS.io formula. <br> <https://hub.docker.com/r/coredns/coredns/> <br> ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/coredns) ![Docker Image Version (latest semver)](https://img.shields.io/docker/v/kometchtech/coredns?sort=semver)|
| dnsdist                          | <https://dnsdist.org/>                                 | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/dnsdist) ![Docker Image Version (latest semver)](https://img.shields.io/docker/v/kometchtech/dnsdist?sort=semver)   |
| BIND9(testing)               | <https://www.isc.org/downloads/bind/>                  | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/bind) ![Docker Image Version (latest semver)](https://img.shields.io/docker/v/kometchtech/bind?sort=semver)                                                                                                                 |
| ISC Kea | <https://www.isc.org/kea/> | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/kea) ![Docker Image Version (latest semver)](https://img.shields.io/docker/v/kometchtech/kea?sort=semver)|
| zabbix-agent (testing)           | <https://www.zabbix.com/>                              | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/zabbix-agent) ![Docker Image Version (latest semver)](https://img.shields.io/docker/v/kometchtech/zabbix-agent?sort=semver)|
| mackerel-agent-plugins (testing) | <https://github.com/mackerelio/mackerel-agent-plugins> |made a deb package for armhf / arm64. <br> <https://github.com/kometchtech/mackerel-agent-plugins> |
| DNSCrypt Proxy                   | <https://github.com/jedisct1/dnscrypt-proxy>           | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/dnscrypt-proxy) ![Docker Image Version (latest semver)](https://img.shields.io/docker/v/kometchtech/dnscrypt-proxy?sort=semver)                                                                                             |
| Stubby                           | <https://github.com/getdnsapi/stubby>                  | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/stubby) ![Docker Image Version (latest semver)](https://img.shields.io/docker/v/kometchtech/stubby?sort=semver)                                                                                                             |
| gobetween (testing)                       | <https://github.com/yyyar/gobetween>                   | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/gobetween?style=flat-square)                                                                                                    |
| glider (testing)                          | <https://github.com/nadoo/glider>                      | ![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/glider?style=flat-square)                                                                                                             |
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

