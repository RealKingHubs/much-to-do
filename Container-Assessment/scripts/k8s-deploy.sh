#!/usr/bin/env sh
# Exit immediately if a command fails (-e) or an undefined variable is used (-u)
set -eu

# --- Environment Setup ---
# Resolve absolute paths for the script and project root
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"

# Define default values for cluster, images, and configuration paths
CLUSTER_NAME="${CLUSTER_NAME:-muchtodo}"
IMAGE_NAME="${IMAGE_NAME:-muchtodo-backend:local}"
NAMESPACE="${NAMESPACE:-muchtodo}"
KIND_CONFIG="${KIND_CONFIG:-$ROOT_DIR/kind/cluster-config.yaml}"

# Ingress-NGINX controller details for kind compatibility
INGRESS_MANIFEST="${INGRESS_MANIFEST:-https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/kind/deploy.yaml}"
INGRESS_CONTROLLER_IMAGE="${INGRESS_CONTROLLER_IMAGE:-registry.k8s.io/ingress-nginx/controller:v1.12.1}"
INGRESS_ADMISSION_IMAGE="${INGRESS_ADMISSION_IMAGE:-registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.5.2}"
ROLLOUT_TIMEOUT="${ROLLOUT_TIMEOUT:-600s}"

# Helper function to manually load Docker images into each Kind node's container runtime (containerd)
# This is often faster and more reliable than 'kind load docker-image' for multiple images
load_image_into_kind() {
  image="$1"
  for node in $(kind get nodes --name "$CLUSTER_NAME"); do
    docker save "$image" | docker exec -i "$node" ctr --namespace=k8s.io images import -
  done
}

# --- Prepare Images ---
# Build the local backend and pre-pull required ingress images to the host
docker build --tag "$IMAGE_NAME" "$ROOT_DIR"
docker pull "$INGRESS_CONTROLLER_IMAGE"
docker pull "$INGRESS_ADMISSION_IMAGE"

# --- Cluster Management ---
# Check if the cluster exists. If it exists but is unreachable, recreate it.
if kind get clusters | grep -qx "$CLUSTER_NAME"; then
  if ! kubectl cluster-info --context "kind-$CLUSTER_NAME" >/dev/null 2>&1; then
    kind delete cluster --name "$CLUSTER_NAME"
    kind create cluster --name "$CLUSTER_NAME" --config "$KIND_CONFIG"
  fi
else
  kind create cluster --name "$CLUSTER_NAME" --config "$KIND_CONFIG"
fi

# Switch kubectl context to the new/existing Kind cluster
kubectl config use-context "kind-$CLUSTER_NAME" >/dev/null 2>&1 || true

# Transfer the images from the host Docker engine to the Kind nodes
load_image_into_kind "$IMAGE_NAME"
load_image_into_kind "$INGRESS_CONTROLLER_IMAGE"
load_image_into_kind "$INGRESS_ADMISSION_IMAGE"

# --- Infrastructure Setup (Ingress) ---
# Install the NGINX Ingress Controller if the namespace doesn't exist
if ! kubectl get namespace ingress-nginx >/dev/null 2>&1; then
  kubectl apply -f "$INGRESS_MANIFEST"
fi

# Wait for Ingress setup jobs (certificates/admission webhooks) to complete
kubectl wait \
  --namespace ingress-nginx \
  --for=condition=complete job/ingress-nginx-admission-create \
  --timeout=180s

kubectl wait \
  --namespace ingress-nginx \
  --for=condition=complete job/ingress-nginx-admission-patch \
  --timeout=180s

# Wait for the Ingress Controller Pod to be healthy and ready to route traffic
kubectl wait \
  --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

# --- Application Deployment ---
# Apply the application manifests in order: Namespace -> DB -> Backend -> Routing
kubectl apply -f "$ROOT_DIR/kubernetes/namespace.yaml"
kubectl apply -f "$ROOT_DIR/kubernetes/mongodb"
kubectl apply -f "$ROOT_DIR/kubernetes/backend"
kubectl apply -f "$ROOT_DIR/kubernetes/ingress.yaml"

# Wait for the deployments to finish rolling out successfully
kubectl -n "$NAMESPACE" rollout status deployment/mongodb --timeout="$ROLLOUT_TIMEOUT"
kubectl -n "$NAMESPACE" rollout status deployment/backend --timeout="$ROLLOUT_TIMEOUT"

# Show the final state of the resources in the namespace
kubectl -n "$NAMESPACE" get pods,svc,ingress
