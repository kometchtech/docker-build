FROM arm64v8/alpine:latest

RUN apk add --no-cache --update dhcp \
    && mkdir -p /var/lib/dhcpd/ \
    && touch /var/lib/dhcpd/dhcpd6.leases

WORKDIR /etc/dhcp
CMD dhcpd -6 --no-pid -f -cf /etc/dhcp/dhcpd.conf eth0
