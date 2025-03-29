#!/usr/bin/env sh
# Entrypoint script for Knot DNS container

set -e

# Create necessary directories if they don't exist
for dir in /etc/knot /run/knot /var/lib/knot; do
  if [ ! -d "$dir" ]; then
    echo "Creating directory: $dir"
    mkdir -p "$dir"
  fi
done

# Clean up any stale socket or pid files
if [ -d /run/knot ]; then
  if [ -f /run/knot/knot.pid ] || [ -f /run/knot/knot.sock ]; then
    rm -f /run/knot/knot.*
  fi 
fi

# Initialize configuration database if it doesn't exist
if [ ! -d /var/lib/knot/confdb ]; then
  echo "Initializing configuration database..."
  knotc conf-init
fi

# Ensure we have a proper configuration
if [ -f /etc/knot-dns/knot.sample.conf ]; then
  # Copy the sample config to the standard location
  cp /etc/knot-dns/knot.sample.conf /etc/knot/knot.conf
  
  # Update user to root for Docker usage
  sed -i 's|user: knot:knot|user: root:root|g' /etc/knot/knot.conf
  
  # Uncomment listen directives and set to listen on all interfaces
  sed -i 's|#    listen: \[ 127.0.0.1@53, ::1@53 \]|    listen: \[ 0.0.0.0@53 \]|g' /etc/knot/knot.conf
  
  # Change log target to stdout
  sed -i 's|  - target: syslog|  - target: stdout|g' /etc/knot/knot.conf
fi

# Start Knot DNS with configuration in non-daemon mode
if [ -f /etc/knot/knot.conf ]; then
  echo "Checking configuration..."
  knotc -c /etc/knot/knot.conf conf-check 
  echo "Starting Knot DNS with configuration..."
  knotd -d -v -c /etc/knot/knot.conf "$@"
else
  echo "No configuration found, starting Knot DNS with default settings..."
  # Run in foreground with verbosity
  exec knotd -d -v "$@"
fi

## If knotd exits or doesn't take over as the main process, keep container running
## This is a fallback in case knotd daemonizes itself despite our efforts
echo "Knot DNS might have daemonized, keeping container alive..."
exec tail -f /dev/null

