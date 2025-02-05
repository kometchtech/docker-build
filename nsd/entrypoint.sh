#!/bin/bash
set -e

# Function to update DNS zone files
update_zones() {
    for zone in /etc/nsd/zones/*.zone; do
        if [ -f "$zone" ]; then
            zone_name=$(basename "$zone" .zone)
            nsd-control reload "$zone_name"
        fi
    done
}

# Check if we're running as root
if [ "$(id -u)" = '0' ]; then
    # Ensure NSD directories have correct permissions
    chown -R nsd:nsd /var/cache/nsd /var/run/nsd /etc/nsd/zones
    chmod 755 /var/cache/nsd /var/run/nsd /etc/nsd/zones

    # If command starts with an option, prepend nsd
    if [ "${1#-}" != "$1" ]; then
        set -- nsd "$@"
    fi

#    # If the command is nsd, switch to the nsd user
#    if [ "$1" = 'nsd' ]; then
#        exec nsd "$@"
#    fi
fi

# Run command with exec to replace shell with the command
exec "$@"
