FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends isc-dhcp-server \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/lib/dhcpd /etc/dhcp \
    && touch /var/lib/dhcpd/dhcpd6.leases

WORKDIR /etc/dhcp
CMD ["dhcpd", "-6", "--no-pid", "-f", "-cf", "/etc/dhcp/dhcpd.conf", "eth0"]

# OCI image metadata
LABEL org.opencontainers.image.title="ISC DHCP Server" \
      org.opencontainers.image.description="ISC DHCPv6 server container" \
      org.opencontainers.image.url="https://www.isc.org/dhcp/" \
      org.opencontainers.image.documentation="https://www.isc.org/dhcp/" \
      org.opencontainers.image.authors="kometchtech <kometch@gmail.com>"
