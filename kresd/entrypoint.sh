#!/usr/bin/env sh

set -e

ROOTKEY=${ROOTKEY:-"/var/cache/knot-resolver/root.keys"}
CACHE=${CACHE:-"/var/cache/knot-resolver"}

# Deleting the trust anchor key file
if [ -e ${ROOTKEY} ]; then
    rm -f ${ROOTKEY}
fi
# Process execution
var="$@"
# Knot Resolver Garbage Collector daemon
kres-cache-gc -c ${CACHE} -d 1000 &
# Knot Resolver daemon
/usr/sbin/kresd ${var}
# process foreground
fg %1
