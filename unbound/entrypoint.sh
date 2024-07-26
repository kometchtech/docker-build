#!/usr/bin/env bash

set +e

ETC="/etc/unbound"

if [ ! -f ${ETC}/unbound_server.pem ]; then
  unbound-control-setup
fi

# generate root.key
if [ ! -f ${ETC}/root.key ]; then
  unbound-anchor -a "${ETC}/root.key"
fi

if [ "${1#-}" != "$1" ]; then
    set -- unbound "$@"
fi

exec "$@"
