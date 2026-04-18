#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
IMAGE_NAME="${IMAGE_NAME:-muchtodo-backend:local}"

docker build --tag "$IMAGE_NAME" "$ROOT_DIR"
