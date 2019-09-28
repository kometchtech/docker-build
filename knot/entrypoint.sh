#!/usr/bin/env sh

set -e

if [ -d /run/knot ]; then
  if [ -f /run/knot/knot.pid ] || [ -f /run/knot/knot.sock ]; then
    rm /run/knot/knot.*
  fi 
fi

if [ ! -f /var/lib/knot/confdb/data.mdb ]; then
  knotc conf-init
fi

if [ -f /etc/knot/knot.conf ]; then
  knotc conf-check
  knotd -v -c /etc/knot/knot.conf
else
  knotd -v -c /etc/knot/knot.example.conf
fi

tail -f /dev/null
