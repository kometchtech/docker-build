#!/usr/bin/env ash

set -e

if [ ! -f /usr/local/etc/nsd_server.pem ]; then
  nsd-control-setup
fi
# change owner and group
#chown -R nsd:nsd /usr/local/etc/nsd /usr/local/etc/nsd/zones /usr/local/var/db/nsd /var/run/nsd

if [ ! -d /var/run/nsd ]; then
    mkdir -p /var/run/nsd
fi

$@

tail -f /dev/null
