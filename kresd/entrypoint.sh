#!/usr/bin/env sh

set -ex

ROOTKEY=${ROOTKEY:-"/var/cache/knot-resolver/root.keys"}
CACHE=${CACHE:-"/var/cache/knot-resolver"}
#GC_OPT=${GC_OPT:-"-d 1000"}

# Deleting the trust anchor key file
if [ -e ${ROOTKEY} ]; then
    rm -f ${ROOTKEY}
fi

## Knot Resolver Garbage Collector daemon
#sleep 10 &
mkdir -p "$CACHE"
kres-cache-gc -c ${CACHE} ${GC_OPT}

# Knot Resolver daemon
if [ "${1#-}" != "$1" ]; then
    #set -- /usr/local/sbin/kresd "$@"
    exec kresd "$@"
else
    exec "$@"
fi
#exec "$@" &



# process foreground
#fg %1
