#!/bin/sh
set -e

# Ensure runtime directories exist
if [ ! -d "/var/run/pdns-recursor" ]; then
  mkdir -p /var/run/pdns-recursor
  chown pdns-recursor:pdns-rec /var/run/pdns-recursor
fi

# Set proper permissions for data directories
chown -R pdns-recursor:pdns-rec /var/lib/pdns-recursor

# Handle command line arguments
if [ "${1#-}" != "$1" ]; then
  set -- pdns_recursor "$@"
fi

# Execute the process
exec "$@"
