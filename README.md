# MuchTodo - Container Orchestration Assessment

This repository contains the containerization and orchestration setup for the **MuchTodo** Golang API and MongoDB database, developed for the StartupTech DevOps initiative.

##  Project Overview
- **Backend:** Golang API (Port 8080)
- **Database:** MongoDB 8.0 (Persistent)
- **Orchestration:** Docker Compose (Development) & Kubernetes/Kind (Production-like)

##  Architecture & Features
- **Security:** Dockerfile uses a non-root `app` user and multi-stage builds to minimize attack surface.
- **Persistence:** MongoDB data is persisted via Docker Volumes (Compose) and PersistentVolumeClaims (K8s).
- **Traffic Management:** NGINX Ingress Controller handles routing to the backend replicas.
- **Automation:** Bash scripts handle the entire lifecycle from cluster creation to teardown.

---

## 📸 Deployment Evidence

### 1. Docker & Local Development
- **Build Success:** Proof of optimized multi-stage build.
  ![Docker Build](./Container-Assessment/evidence/01-docker-build.png)
- **Local Runtime:** Backend and MongoDB running via Compose with health checks.
  ![Docker Compose](./Container-Assessment/evidence/02-docker-compose-up.png)
  ![Compose Health](./Container-Assessment/evidence/03-docker-compose-health.png)

### 2. Kubernetes Orchestration (Kind)
- **Cluster & Infrastructure:** Kind cluster setup with Ingress-NGINX controller.
  ![Kind Cluster](./Container-Assessment/evidence/05-kind-cluster-created.png)
- **Workload Status:** All pods (2x Backend, 1x MongoDB) running in the `muchtodo` namespace.
  ![Kubectl Pods](./Container-Assessment/evidence/06-kubectl-pods.png)
- **Network & Access:** Services and Ingress resources correctly configured.
  ![Kubectl Services](./Container-Assessment/evidence/08-kubectl-services.png)
  ![Kubectl Ingress](./Container-Assessment/evidence/07-kubectl-ingress.png)
- **End-to-End Test:** Application accessible via curl through the Ingress/NodePort.
  ![App Access](./Container-Assessment/evidence/11-k8s-application-access.png)
  ![App Health](./Container-Assessment/evidence/10-k8s-application-health.png)

---

##  Quick Start

### Prerequisites
- Docker & Docker Compose
- Kind & Kubectl

### Automated Deployment
To spin up the entire Kubernetes environment (Cluster + Ingress + App):
```bash
./scripts/k8s-deploy.sh
```

### Cleanup
To remove all Kubernetes resources and the Kind cluster:
```bash
DELETE_CLUSTER=true ./scripts/k8s-cleanup.sh
```
