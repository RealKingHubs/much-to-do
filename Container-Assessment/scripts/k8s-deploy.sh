#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
CLUSTER_NAME="${CLUSTER_NAME:-muchtodo}"
IMAGE_NAME="${IMAGE_NAME:-muchtodo-backend:local}"
NAMESPACE="${NAMESPACE:-muchtodo}"
KIND_CONFIG="${KIND_CONFIG:-$ROOT_DIR/kind/cluster-config.yaml}"
INGRESS_MANIFEST="${INGRESS_MANIFEST:-https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/kind/deploy.yaml}"
INGRESS_CONTROLLER_IMAGE="${INGRESS_CONTROLLER_IMAGE:-registry.k8s.io/ingress-nginx/controller:v1.12.1}"
INGRESS_ADMISSION_IMAGE="${INGRESS_ADMISSION_IMAGE:-registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.5.2}"
ROLLOUT_TIMEOUT="${ROLLOUT_TIMEOUT:-600s}"

load_image_into_kind() {
  image="$1"

  for node in $(kind get nodes --name "$CLUSTER_NAME"); do
    docker save "$image" | docker exec -i "$node" ctr --namespace=k8s.io images import -
  done
}

docker build --tag "$IMAGE_NAME" "$ROOT_DIR"
docker pull "$INGRESS_CONTROLLER_IMAGE"
docker pull "$INGRESS_ADMISSION_IMAGE"

if kind get clusters | grep -qx "$CLUSTER_NAME"; then
  if ! kubectl cluster-info --context "kind-$CLUSTER_NAME" >/dev/null 2>&1; then
    kind delete cluster --name "$CLUSTER_NAME"
    kind create cluster --name "$CLUSTER_NAME" --config "$KIND_CONFIG"
  fi
else
  kind create cluster --name "$CLUSTER_NAME" --config "$KIND_CONFIG"
fi

kubectl config use-context "kind-$CLUSTER_NAME" >/dev/null 2>&1 || true

load_image_into_kind "$IMAGE_NAME"
load_image_into_kind "$INGRESS_CONTROLLER_IMAGE"
load_image_into_kind "$INGRESS_ADMISSION_IMAGE"

if ! kubectl get namespace ingress-nginx >/dev/null 2>&1; then
  kubectl apply -f "$INGRESS_MANIFEST"
fi

kubectl wait \
  --namespace ingress-nginx \
  --for=condition=complete job/ingress-nginx-admission-create \
  --timeout=180s

kubectl wait \
  --namespace ingress-nginx \
  --for=condition=complete job/ingress-nginx-admission-patch \
  --timeout=180s

kubectl wait \
  --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

kubectl apply -f "$ROOT_DIR/kubernetes/namespace.yaml"
kubectl apply -f "$ROOT_DIR/kubernetes/mongodb"
kubectl apply -f "$ROOT_DIR/kubernetes/backend"
kubectl apply -f "$ROOT_DIR/kubernetes/ingress.yaml"

kubectl -n "$NAMESPACE" rollout status deployment/mongodb --timeout="$ROLLOUT_TIMEOUT"
kubectl -n "$NAMESPACE" rollout status deployment/backend --timeout="$ROLLOUT_TIMEOUT"
kubectl -n "$NAMESPACE" get pods,svc,ingress
