# docker-build

personal docker build

It exists to check the operation of container in the ARM environment (arm64).
> For arm32, tackle depending on the mood.

Basically we will check the operation of the following application.

## base images

- Debian stretch/testing
- alpine edge

## check software

- dibbler-server <http://klub.com.pl/dhcpv6/>
- NSD <https://www.nlnetlabs.nl/projects/nsd/>
- Unbound <https://www.nlnetlabs.nl/projects/unbound/>
- PowerDNS recursor <https://www.powerdns.com/recursor.html>
- Knot DNS resolver <https://www.knot-resolver.cz/>
- CoreDNS <https://coredns.io/>
- dnsdist <https://dnsdist.org/>
- BIND9 (testing) <https://www.isc.org/downloads/bind/> alpine package
- zabbix-agent (testing) <https://www.zabbix.com/>
- mackerel-plugin (testing) <https://github.com/mackerelio/mackerel-agent-plugins>

## Tips

- configuration IPv6

```bash
echo '{"ipv6":true, "fixed-cidr-v6":"2001:db8:1::/64"}' | sudo tee -a /etc/docker/daemon.json
sudo systemctl restart docker.service
```
