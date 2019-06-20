#!/bin/sh

if [ -d /run/knot ]; then
  if [ -f /run/knot/knot.pid ] || [ -f /run/knot/knot.sock ]; then
    rm /run/knot/knot.*
  fi 
fi

if [ ! -f /var/lib/knot/confdb/data.mdb ]; then
  /sbin/knotc conf-init
fi

if [ -f /etc/knot/knot.conf ]; then
  /sbin/knotc conf-check
  /sbin/knotd -v -c /etc/knot/knot.conf
else
  /sbin/knotd -v -c /etc/knot/knot.example.conf
fi

