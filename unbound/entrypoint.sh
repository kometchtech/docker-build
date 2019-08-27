#!/usr/bin/env ash

set -m

ETC="/etc/unbound"

if [ ! -f ${ETC}/unbound_server.pem ]; then
  unbound-control-setup
fi

# generate root.key
if [ ! -f ${ETC}/root.key ]; then
  unbound-anchor -a "${ETC}/root.key"
fi

## change owner
#chown -R unbound:unbound /etc/unbound

if [ ! -f ${ETC}/unbound.conf ]; then
  unbound -d $@
else
  unbound -d -c ${ETC}/unbound.conf
fi
fg %1
