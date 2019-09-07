#!/usr/bin/env sh

mkdir -p /var/run/pdns-recursor/

var="$@"
echo $var

if [ -f /etc/powerdns/recursor.conf ]; then
    pdns_recursor --disable-syslog --daemon=no --write-pid=no $var
else
    exit 1
fi
