#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
CLUSTER_NAME="${CLUSTER_NAME:-muchtodo}"

kubectl delete -f "$ROOT_DIR/kubernetes/ingress.yaml" --ignore-not-found
kubectl delete -f "$ROOT_DIR/kubernetes/backend" --ignore-not-found
kubectl delete -f "$ROOT_DIR/kubernetes/mongodb" --ignore-not-found
kubectl delete -f "$ROOT_DIR/kubernetes/namespace.yaml" --ignore-not-found

if [ "${DELETE_CLUSTER:-false}" = "true" ]; then
  kind delete cluster --name "$CLUSTER_NAME"
fi
