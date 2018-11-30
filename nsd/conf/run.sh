#!/bin/sh

if [ ! -f /usr/local/etc/nsd_server.pem ]; then
  nsd-control-setup
fi

chown -R nsd:nsd /usr/local/etc/nsd /usr/local/etc/nsd/zones /usr/local/var/db/nsd /var/run/nsd

/usr/local/sbin/nsd -d -P /var/run/nsd/nsd.pid -c /etc/nsd/nsd.conf
