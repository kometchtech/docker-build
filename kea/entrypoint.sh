#!/usr/bin/env sh


RUNPATH="/usr/local/var/run/kea"

if [ -e "${RUNPATH}/kea-dhcp4.kea-dhcp4.pid" ]; then
    rm -f "${RUNPATH}/kea-dhcp4.kea-dhcp4.pid"
fi
if [ -e "${RUNPATH}/kea-dhcp6.kea-dhcp6.pid" ]; then
    rm -f "${RUNPATH}/kea-dhcp6.kea-dhcp6.pid"
fi

sh -c  "keactrl start -c /etc/kea/keactrl.conf"

tail -f /dev/null
