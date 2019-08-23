#!/bin/ash

if [ -e /usr/var/run/kea/kea-dhcp4.kea-dhcp4.pid ]; then
    rm -f /usr/var/run/kea/kea-dhcp4.kea-dhcp4.pid
fi
if [ -e /usr/var/run/kea/kea-dhcp6.kea-dhcp6.pid ]; then
    rm -f /usr/var/run/kea/kea-dhcp6.kea-dhcp6.pid
fi

/usr/sbin/keactrl start -c /etc/kea/keactrl.conf
tail -f /dev/null
