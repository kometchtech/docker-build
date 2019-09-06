#!/usr/bin/env sh

mkdir -p /var/run/pdns-recursor/

if [ ! -f /etc/powerdns/recursor.conf ]; then
    pdns_recursor --disable-syslog --log-timestamp=yes -c /etc/powerdns/recursor.conf
else
    pdns_recursor --disable-syslog --log-timestamp=yes
fi

fg %1
