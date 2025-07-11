#!/usr/bin/env sh

# Exit immediately if a command exits with a non-zero status
# Treat unset variables as an error when substituting
set -e -u

# Define run path for Kea PID files
RUNPATH="/usr/local/var/run/kea"

# Ensure the run directory exists with proper permissions
mkdir -p "${RUNPATH}"
chmod 750 "${RUNPATH}"

# Remove any existing PID files to prevent startup issues
for PID_FILE in "kea-dhcp4.kea-dhcp4.pid" "kea-dhcp6.kea-dhcp6.pid" "kea-ctrl-agent.kea-ctrl-agent.pid"; do
    if [ -e "${RUNPATH}/${PID_FILE}" ]; then
        echo "Removing existing PID file: ${PID_FILE}"
        rm -f "${RUNPATH}/${PID_FILE}"
    fi
done

# Set proper ownership for kea user
chown -R kea:kea "${RUNPATH}" /var/lib/kea

# Check if we're running as root
if [ "$(id -u)" = "0" ]; then
    echo "Starting Kea services as root, then dropping privileges..."

    # Start Kea services using keactrl
    echo "Starting Kea services..."
    keactrl start -c /etc/kea/keactrl.conf

    # Keep container running
    echo "Kea services started. Container is now running..."
    exec tail -f /dev/null
else
    echo "Starting Kea services as user kea..."

    # Start Kea services using keactrl
    echo "Starting Kea services..."
    keactrl start -c /etc/kea/keactrl.conf

    # Keep container running
    echo "Kea services started. Container is now running..."
    exec tail -f /dev/null
fi
