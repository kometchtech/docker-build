#!/bin/sh

# Execute the command passed to the container
# This allows for overriding the default CMD at runtime

set -e

exec "$@"
