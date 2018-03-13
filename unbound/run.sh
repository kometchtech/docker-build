#!/bin/sh

if [ ! -f /etc/unbound/unbound_server.pem ]; then
  unbound-control-setup
fi

# change owner
chown -R unbound:unbound /etc/unbound

/usr/local/sbin/unbound -d -c /etc/unbound/unbound.conf
