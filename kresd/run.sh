#!/usr/bin/env sh

rm -f /etc/knot-resolver/root.keys
/usr/sbin/kresd -f $(nproc --all) $@

wait

