#!/usr/bin/env sh

# Exit immediately if a command fails (-e) or an unset variable is used (-u)
set -eu

# Get the absolute path to the directory where this script is located
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

# Get the absolute path to the project root (one level up from the script)
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"

# Set the Docker image name, defaulting to 'muchtodo-backend:local' if not provided
IMAGE_NAME="${IMAGE_NAME:-muchtodo-backend:local}"

# Build the Docker image using the project root as the context
docker build --tag "$IMAGE_NAME" "$ROOT_DIR"
