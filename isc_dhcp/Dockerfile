FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends isc-dhcp-server \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/lib/dhcpd /etc/dhcp \
    && touch /var/lib/dhcpd/dhcpd6.leases

WORKDIR /etc/dhcp
CMD ["dhcpd", "-6", "--no-pid", "-f", "-cf", "/etc/dhcp/dhcpd.conf", "eth0"]
