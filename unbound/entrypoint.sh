#!/usr/bin/env bash

set -eo pipefail

ETC="/etc/unbound"
VAR_LIB="/var/lib/unbound"

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Setup unbound control if not already done
if [ ! -f "${ETC}/unbound_server.pem" ]; then
    log "Setting up unbound-control..."
    unbound-control-setup
fi

# Generate root.key if not present
if [ ! -f "${VAR_LIB}/root.key" ]; then
    log "Generating root.key..."
    unbound-anchor -a "${VAR_LIB}/root.key" || log "Warning: Failed to generate root.key"
fi

# Check if the first argument is a flag
if [ "${1#-}" != "$1" ]; then
    set -- unbound "$@"
fi

# Execute the command
log "Starting Unbound..."
exec "$@"
