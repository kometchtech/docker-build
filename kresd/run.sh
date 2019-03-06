#!/usr/bin/env sh

rm -f /etc/knot-resolver/root.keys
/usr/local/sbin/kresd -f $(nproc --all) $@

wait

