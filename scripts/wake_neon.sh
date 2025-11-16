#!/bin/bash
# Wake up Neon database before deployment
# This prevents DNS resolution failures when compute is suspended

set -e

echo "Waking up Neon database..."

# Run a simple query to wake the compute endpoint
# The query will succeed or fail, but it will wake the endpoint
psql "$DATABASE_URL" -c "SELECT 1;" > /dev/null 2>&1 || true

# Wait a moment for the compute to fully start
echo "Waiting for compute to be fully active..."
sleep 5

# Verify connection works
if psql "$DATABASE_URL" -c "SELECT version();" > /dev/null 2>&1; then
    echo "✓ Neon database is active and responding"
    exit 0
else
    echo "✗ Failed to connect to Neon database"
    exit 1
fi
