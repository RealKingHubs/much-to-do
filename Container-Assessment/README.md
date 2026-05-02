# Container Assessment

This repository contains the containerization and local Kubernetes deployment setup for the existing MuchToDo backend application.

Important constraint followed throughout this work:

- No file inside `Server/` was modified.

The backend source code lives in `Server/MuchToDo`, while all container, Kubernetes, script, and documentation work was added at the project root.

## Project Overview

The application is a Golang backend API that:

- listens on port `8080`
- connects to MongoDB
- reads configuration from environment variables
- exposes a health endpoint at `/health`

This project adds:

- a production-style multi-stage Dockerfile
- a local Docker Compose setup for backend + MongoDB
- Kubernetes manifests for MongoDB, backend, namespace, and ingress
- helper scripts for Docker and Kind workflows
- evidence and explanation files for submission support

## Project Structure

```text
container-assessment/
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── .env
├── .env.example
├── docker-entrypoint.sh
├── kind/
│   └── cluster-config.yaml
├── kubernetes/
│   ├── namespace.yaml
│   ├── mongodb/
│   │   ├── mongodb-secret.yaml
│   │   ├── mongodb-configmap.yaml
│   │   ├── mongodb-pvc.yaml
│   │   ├── mongodb-deployment.yaml
│   │   └── mongodb-service.yaml
│   ├── backend/
│   │   ├── backend-secret.yaml
│   │   ├── backend-configmap.yaml
│   │   ├── backend-deployment.yaml
│   │   └── backend-service.yaml
│   └── ingress.yaml
├── scripts/
│   ├── docker-build.sh
│   ├── docker-run.sh
│   ├── k8s-deploy.sh
│   └── k8s-cleanup.sh
├── evidence/
├── README.md
└── Server/
    └── MuchToDo/
```

## Prerequisites

Before running anything, make sure these are installed on your machine:

- Docker Desktop
- Kind
- kubectl
- Git Bash or another POSIX-compatible shell for running the `.sh` scripts on Windows

Recommended verification commands:

```bash
docker --version
kind --version
kubectl version --client
```

## Environment Configuration

This project uses a root-level `.env` file for the local Docker setup.

The current `.env` contains the values used for local development.  
The `.env.example` file is the template version.

### Root `.env` variables

- `APP_PORT`: host port for backend access
- `PORT`: application port inside the backend container
- `MONGO_PORT`: host port for MongoDB
- `MONGO_INITDB_ROOT_USERNAME`: MongoDB root username
- `MONGO_INITDB_ROOT_PASSWORD`: MongoDB root password
- `DB_NAME`: application database name
- `MONGO_URI`: backend MongoDB connection string
- `JWT_SECRET_KEY`: JWT signing secret
- `JWT_EXPIRATION_HOURS`: token lifetime
- `ENABLE_CACHE`: Redis cache toggle
- `LOG_LEVEL`: log level
- `LOG_FORMAT`: log output format

### Why `docker-entrypoint.sh` exists

The backend application in `Server/MuchToDo` loads configuration more reliably when it can read an actual `.env` file at runtime.

To avoid modifying anything inside `Server/`, the container starts with `docker-entrypoint.sh`, which:

1. reads the runtime environment variables
2. writes them into `/app/.env`
3. starts the Go binary

## Docker Setup

### 1. Build the backend image

Use the helper script:

```bash
./scripts/docker-build.sh
```

Or directly:

```bash
docker build -t muchtodo-backend:local .
```

### 2. Start the local Docker stack

Use the helper script:

```bash
./scripts/docker-run.sh
```

Or directly:

```bash
docker compose up --build -d
```

This starts:

- `muchtodo-mongodb`
- `muchtodo-backend`

### 3. Check container status

```bash
docker compose ps
docker compose logs -f backend
docker compose logs -f mongodb
```

### 4. Test the local backend

```bash
curl http://localhost:8080/health
```

Expected result: a healthy JSON response from the backend.

### 5. Stop the local Docker stack

```bash
docker compose down
```

To remove MongoDB data as well:

```bash
docker compose down -v
```

## Kubernetes Setup with Kind

### 1. What the Kind config does

The file `kind/cluster-config.yaml`:

- creates a single control-plane Kind cluster
- adds the label `ingress-ready=true` so ingress-nginx can run
- maps these host ports:
  - `80` for ingress HTTP
  - `443` for ingress HTTPS
  - `30080` for backend NodePort access

### 2. Deploy everything to Kind

Use:

```bash
./scripts/k8s-deploy.sh
```

### 3. What `k8s-deploy.sh` does

The deployment script performs these steps:

1. builds the backend image
2. pulls the ingress controller images on the host
3. creates the Kind cluster if it does not exist
4. recreates the Kind cluster if the saved context exists but the API server is unreachable
5. switches `kubectl` to the correct Kind context
6. imports the backend and ingress images into the Kind node runtime
7. installs ingress-nginx if it is not already installed
8. waits for ingress admission jobs and ingress controller readiness
9. applies the namespace
10. applies MongoDB manifests
11. applies backend manifests
12. applies ingress manifest
13. waits for MongoDB rollout
14. waits for backend rollout
15. prints the resulting pods, services, and ingress

### 4. Rollout timeout

The script uses:

```bash
ROLLOUT_TIMEOUT=600s
```

by default because the first pull of `mongo:8.0` on a fresh Kind node can take several minutes.

If needed, you can override it:

```bash
ROLLOUT_TIMEOUT=900s ./scripts/k8s-deploy.sh
```

## Kubernetes Manifests Summary

### Namespace

- `kubernetes/namespace.yaml`
- creates namespace `muchtodo`

### MongoDB resources

- `mongodb-secret.yaml`: MongoDB credentials
- `mongodb-configmap.yaml`: MongoDB database name
- `mongodb-pvc.yaml`: persistent storage claim
- `mongodb-deployment.yaml`: MongoDB pod with probes and mounted storage
- `mongodb-service.yaml`: internal ClusterIP service

### Backend resources

- `backend-secret.yaml`: backend secret values such as `MONGO_URI` and `JWT_SECRET_KEY`
- `backend-configmap.yaml`: backend non-secret settings such as `PORT`, `DB_NAME`, and log settings
- `backend-deployment.yaml`: backend deployment with 2 replicas, resource limits, liveness probe, and readiness probe
- `backend-service.yaml`: NodePort service exposing the backend on `30080`

### Ingress resource

- `kubernetes/ingress.yaml`
- routes traffic from the NGINX ingress controller to the backend service

## Verify the Kubernetes Deployment

After deployment, run:

```bash
kubectl get pods -n muchtodo
kubectl get svc -n muchtodo
kubectl get ingress -n muchtodo
kubectl get pvc -n muchtodo
```

You should see:

- MongoDB pod `Running`
- backend pods `Running`
- backend service on `NodePort 30080`
- ingress using class `nginx`
- MongoDB PVC in `Bound` state

### Check rollout status manually

```bash
kubectl rollout status deployment/mongodb -n muchtodo
kubectl rollout status deployment/backend -n muchtodo
```

### Check backend logs

```bash
kubectl logs -n muchtodo deployment/backend --tail=100
```

### Test application access

Using NodePort:

```bash
curl http://localhost:30080/health
```

Using ingress:

```bash
curl http://localhost/health
```

If `curl` is unavailable, you can also port-forward:

```bash
kubectl port-forward -n muchtodo svc/backend 8080:80
```

Then open:

```text
http://localhost:8080/health
```

## Cleanup

To remove deployed Kubernetes resources but keep the Kind cluster:

```bash
./scripts/k8s-cleanup.sh
```

To remove the resources and also delete the Kind cluster:

```bash
DELETE_CLUSTER=true ./scripts/k8s-cleanup.sh
```

## Evidence for Submission

The `evidence/` folder is reserved for screenshots and supporting outputs requested by the assessment.

Recommended evidence to capture:

1. Docker build completion
2. Docker Compose services running
3. backend `/health` working through Docker
4. Kind cluster creation
5. Kubernetes pods running
6. backend reachable through NodePort
7. backend reachable through ingress
8. `kubectl get pods`, `kubectl get svc`, and `kubectl get ingress` outputs

Supporting evidence files already in the repository:

- `evidence/01-docker-build.png`
- `evidence/02-docker-compose-up.png`
- `evidence/03-docker-compose-health.png`
- `evidence/05-kind-cluster-created.png`
- `evidence/06-kubectl-pods.png`
- `evidence/07-kubectl-ingress.png`
- `evidence/08-kubectl-services.png`
- `evidence/09-k8s-nodeport.png`
- `evidence/10-k8s-application-health.png`
- `evidence/11-k8s-application-access.pngd`

## Troubleshooting

### Backend shows invalid MongoDB URI

Cause:

- the backend did not receive the expected runtime configuration

Fix:

```bash
docker compose down
docker compose up --build -d
docker compose logs -f backend
```

### `docker-entrypoint.sh` says `/app/.env: Permission denied`

Cause:

- the image was built before `/app` ownership was corrected

Fix:

```bash
docker compose down
docker compose up --build -d
```

### `kubectl` cannot reach the Kind cluster

Cause:

- the saved Kind context exists, but the cluster is no longer running

Fix:

```bash
kind delete cluster --name muchtodo
./scripts/k8s-deploy.sh
```

### ingress admission jobs fail with image pull errors

Cause:

- the Kind node cannot reliably pull `registry.k8s.io` images directly

Fix:

- use `./scripts/k8s-deploy.sh`
- the script now pulls ingress images on the host and imports them into Kind

### MongoDB rollout times out on first deployment

Cause:

- the first image pull and PVC provisioning may take several minutes

Fix:

```bash
ROLLOUT_TIMEOUT=900s ./scripts/k8s-deploy.sh
```

## Notes

- The original backend code under `Server/` was intentionally left unchanged.
- Redis caching is disabled in this setup because it is optional for this backend.
- Secrets used here are for local development only. Replace them before any real deployment.
- The working Kubernetes namespace is `muchtodo`.
- The backend service is exposed on `localhost:30080` or `muchtodo.local:30080` and through ingress on `localhost` or `muchtodo.local`.
