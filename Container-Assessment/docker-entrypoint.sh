#!/bin/sh

# Immediately exit if a command fails (-e) or if an undefined variable is used (-u)
set -eu

# Set default file permissions so any new files created are only readable/writable by the owner
umask 077

# Generate a .env file dynamically using environment variables passed to the container.
# If a variable isn't set, it uses the default value provided (e.g., PORT defaults to 8080).
cat > /app/.env <<EOF
PORT=${PORT:-8080}
MONGO_URI=${MONGO_URI:-}
DB_NAME=${DB_NAME:-}
JWT_SECRET_KEY=${JWT_SECRET_KEY:-}
JWT_EXPIRATION_HOURS=${JWT_EXPIRATION_HOURS:-72}
ENABLE_CACHE=${ENABLE_CACHE:-false}
REDIS_ADDR=${REDIS_ADDR:-}
REDIS_PASSWORD=${REDIS_PASSWORD:-}
LOG_LEVEL=${LOG_LEVEL:-INFO}
LOG_FORMAT=${LOG_FORMAT:-json}
EOF

# Replace the shell process with the Go application binary.
# Using 'exec' ensures the app receives OS signals (like SIGTERM) directly.
exec /app/muchtodo
