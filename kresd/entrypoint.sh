#!/usr/bin/env sh

set +e

ROOTKEY=${ROOTKEY:-"/var/cache/knot-resolver/root.keys"}
CACHE=${CACHE:-"/var/cache/knot-resolver"}

# Deleting the trust anchor key file
if [ -e ${ROOTKEY} ]; then
    rm -f ${ROOTKEY}
fi

# Knot Resolver Garbage Collector daemon
kres-cache-gc -c ${CACHE} -d 10000 &

# Knot Resolver daemon
if [ "${1#-}" != "$1" ]; then
    set -- /usr/local/sbin/kresd "$@"
fi

exec "$@"

# process foreground
fg %1
