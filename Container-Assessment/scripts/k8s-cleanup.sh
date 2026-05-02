#!/usr/bin/env sh

# Exit immediately if a command fails (-e) or an undefined variable is used (-u)
set -eu

# Get the absolute path to the directory where this script is located
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

# Get the absolute path to the project root (one level up from the script)
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"

# Set the name of the kind cluster to target (defaults to 'muchtodo')
CLUSTER_NAME="${CLUSTER_NAME:-muchtodo}"

# Remove the Ingress rules first to stop external traffic
kubectl delete -f "$ROOT_DIR/kubernetes/ingress.yaml" --ignore-not-found

# Remove the Backend application resources
kubectl delete -f "$ROOT_DIR/kubernetes/backend" --ignore-not-found

# Remove the MongoDB database resources (deployments, services, etc.)
kubectl delete -f "$ROOT_DIR/kubernetes/mongodb" --ignore-not-found

# Remove the dedicated namespace (this also deletes any remaining resources inside it)
kubectl delete -f "$ROOT_DIR/kubernetes/namespace.yaml" --ignore-not-found

# If the DELETE_CLUSTER environment variable is set to "true", destroy the entire kind cluster
if [ "${DELETE_CLUSTER:-false}" = "true" ]; then
  kind delete cluster --name "$CLUSTER_NAME"
fi
