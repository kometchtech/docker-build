#!/usr/bin/env ash

set -e

if [ -z $@ ]; then
    named -c /etc/named/named.conf -g -u named
else
    `$@`
fi

#tail -f /dev/null
fg %1
