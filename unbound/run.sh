#!/usr/bin/env ash

if [ ! -f /etc/unbound/unbound_server.pem ]; then
  unbound-control-setup
fi

# generate root.key
if [ ! -f /etc/unbound/root.key ]; then
  unbound-anchor -a "/etc/unbound/root.key"
fi

## change owner
#chown -R unbound:unbound /etc/unbound

if [ ! -f /etc/unbound/unbound.conf ]; then
  /usr/local/sbin/unbound -d $@
else
  /usr/local/sbin/unbound -d -c /etc/unbound/unbound.conf
fi
