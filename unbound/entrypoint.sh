#!/usr/bin/env bash

set -eo pipefail

ETC="/etc/unbound"
NAMED_ROOT_URL="https://www.internic.net/domain/named.root"

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
if [ ! -f "${ETC}/root.key" ]; then
    log "Generating root.key..."
    unbound-anchor -a "${ETC}/root.key" || log "Warning: Failed to generate root.key"
    chown unbound:unbound "${ETC}/root.key"
fi

# Download named.root if not present or if it's outdated
if [ ! -f "${ETC}/named.root" ] || [ "$(curl -sI "${NAMED_ROOT_URL}" | grep -i Last-Modified | awk '{print $2, $3, $4, $5, $6}')" != "$(stat -c %y "${ETC}/named.root" | awk '{print $1, $2}')" ]; then
    log "Downloading named.root..."
    curl -o "${ETC}/named.root" -fsSL "${NAMED_ROOT_URL}" || log "Warning: Failed to download named.root"
fi

# Check if the first argument is a flag
if [ "${1#-}" != "$1" ]; then
    set -- unbound "$@"
fi

# Execute the command
log "Starting Unbound..."
exec "$@"
