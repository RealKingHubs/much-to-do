#!/usr/bin/env sh

# Exit immediately if any command fails (-e) or if an undefined variable is used (-u)
set -eu

# Get the absolute path of the directory where this script lives
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

# Get the project root directory (one level up from the script)
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"

# Start the application using Docker Compose:
# -f specifies the path to the compose file
# up starts the services
# --build ensures images are rebuilt before starting
# -d runs the containers in detached (background) mode
docker compose -f "$ROOT_DIR/docker-compose.yml" up --build -d

# Show the status of the containers to verify they started correctly
docker compose -f "$ROOT_DIR/docker-compose.yml" ps
