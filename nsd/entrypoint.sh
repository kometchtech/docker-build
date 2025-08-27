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
    chmod 0755 /var/cache/nsd /var/run/nsd /etc/nsd/zones
    chmod 1777 /tmp

    # Create nsd working directory with proper permissions
    mkdir -p /var/cache/nsd/nsd-xfr
    chown nsd:nsd /var/cache/nsd/nsd-xfr
    chmod 0755 /var/cache/nsd/nsd-xfr

    # If command starts with an option, prepend nsd with full path
    if [ "${1#-}" != "$1" ]; then
        set -- /usr/local/sbin/nsd "$@"
    fi

    # If the command is nsd (without path), use full path
    if [ "$1" = 'nsd' ]; then
        shift
        set -- /usr/local/sbin/nsd "$@"
    fi
fi

# Run command with exec to replace shell with the command
exec "$@"
