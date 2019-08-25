#!/usr/bin/env sh

# Deleting the trust anchor key file
rm -f /var/cache/knot-resolver/root.keys
# Process execution
var="$@"
# Knot Resolver Garbage Collector daemon
kres-cache-gc -c /var/cache/knot-resolver -d 1000 &
# Knot Resolver daemon
/usr/sbin/kresd $var &
# process foreground
tail -f /dev/null
