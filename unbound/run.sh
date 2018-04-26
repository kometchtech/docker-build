#!/bin/sh

if [ ! -f /etc/unbound/unbound_server.pem ]; then
  unbound-control-setup
fi

# change owner
chown -R unbound:unbound /etc/unbound

if [ -f /etc/unbound/unbound.conf ]; then
  /usr/local/sbin/unbound -d -c /etc/unbound/unbound.conf
else
  /usr/local/sbin/unbound -d
fi
