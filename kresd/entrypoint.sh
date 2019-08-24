#!/usr/bin/env sh

rm -f /etc/knot-resolver/root.keys
sh -c "/usr/sbin/kresd $@"
sh -c "kres-cache-gc -c /etc/knot-resolveri/cache -d 10000"

tail -f /dev/null
