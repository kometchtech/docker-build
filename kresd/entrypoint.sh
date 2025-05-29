#!/usr/bin/env sh

# Exit on error, print commands for debugging
set -ex

# Configure default paths
ROOTKEY=${ROOTKEY:-"/var/cache/knot-resolver/root.keys"}
CACHE=${CACHE:-"/var/cache/knot-resolver"}
# Commented out as it seems unused
#GC_OPT=${GC_OPT:-"-d 1000"}

# Delete trust anchor key file if exists
if [ -e ${ROOTKEY} ]; then
    rm -f ${ROOTKEY}
fi

# Create cache directory if it doesn't exist
mkdir -p "$CACHE"

# Handle different command formats
if [ "${1#-}" != "$1" ]; then
    # If first argument starts with a hyphen, assume it's a flag for kresd
    exec kresd "$@"
else
    # Otherwise, execute the command directly
    exec "$@"
fi
