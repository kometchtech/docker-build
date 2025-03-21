#!/bin/bash

set -e 

if [ -z $# ]; then
    echo "Starting named..."
    $(which named) -c /etc/named/named.conf -g -u _named
else
    echo "Starting named..."
    `$@`
fi


#tail -f /dev/null
#exec "$@"
exec $(which named) $@ 
