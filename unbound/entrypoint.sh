#!/usr/bin/env bash

set -eo pipefail

ETC="/etc/unbound"
NAMED_ROOT_URL="https://www.internic.net/domain/named.root"

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Function to setup unbound control
setup_unbound_control() {
    if [ ! -f "${ETC}/unbound_server.pem" ]; then
        log "Setting up unbound-control..."
        unbound-control-setup
    fi
}

# Function to generate root.key
generate_root_key() {
    if [ ! -f "${ETC}/root.key" ]; then
        log "Generating root.key..."
        unbound-anchor -a "${ETC}/root.key" || log "Warning: Failed to generate root.key"
        chown unbound:unbound "${ETC}/root.key"
    fi
}

# Function to download named.root
download_named_root() {
    local need_download=false
    
    # Check if file exists
    if [ ! -f "${ETC}/named.root" ]; then
        need_download=true
    else
        # Check if remote file is newer than local file
        local remote_modified=$(curl -sI "${NAMED_ROOT_URL}" | grep -i Last-Modified | awk '{print $2, $3, $4, $5, $6}')
        local local_modified=$(stat -c %y "${ETC}/named.root" | awk '{print $1, $2}')
        
        if [ "${remote_modified}" != "${local_modified}" ]; then
            need_download=true
        fi
    fi
    
    if [ "${need_download}" = true ]; then
        log "Downloading named.root..."
        curl -o "${ETC}/named.root" -fsSL "${NAMED_ROOT_URL}" || log "Warning: Failed to download named.root"
    fi
}

# Main function
main() {
    # Setup required files
    setup_unbound_control
    generate_root_key
    download_named_root
    
    # Check if the first argument is a flag
    if [ "${1#-}" != "$1" ]; then
        set -- unbound "$@"
    fi
    
    # Execute the command
    log "Starting Unbound..."
    exec "$@"
}

# Run main function with all script arguments
main "$@"
