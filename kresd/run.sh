#!/usr/bin/env ash

/usr/local/sbin/kresd -f $(nproc --all) $@
