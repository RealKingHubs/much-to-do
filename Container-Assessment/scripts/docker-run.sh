#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"

docker compose -f "$ROOT_DIR/docker-compose.yml" up --build -d
docker compose -f "$ROOT_DIR/docker-compose.yml" ps
