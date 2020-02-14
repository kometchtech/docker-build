#!/usr/bin/env sh

set +e

mkdir -p /var/run/pdns-recursor

if [ "${1#-}" != "$1" ]; then
    set -- pdns_recursor "$@"
fi

exec "$@"
