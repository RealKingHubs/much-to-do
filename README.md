# Open Container Assessment Folder

 This repository contains the containerization and local Kubernetes deployment setup for the existing MuchToDo backend application inside Server folder.

---
## Deployment Evidence

Below are the screenshots confirming the successful build and orchestration of the MuchToDo application.

### Docker & Compose
* **Build Success:** ![Docker Build](./Container-Assessment/evidence/01-docker-build.png)
* **Compose Up:** ![Docker Compose Up](./Container-Assessment/evidence/02-docker-compose-up.png)
* **Health Check:** ![Compose Health](./Container-Assessment/evidence/03-docker-compose-health.png)

### Kubernetes (Kind)
* **Cluster Created:** ![Kind Cluster](./Container-Assessment/evidence/05-kind-cluster-created.png)
* **Pods Status:** ![Kubectl Pods](./Container-Assessment/evidence/06-kubectl-pods.png)
* **Ingress Setup:** ![Kubectl Ingress](./Container-Assessment/evidence/07-kubectl-ingress.png)
* **Services:** ![Kubectl Services](./Container-Assessment/evidence/08-kubectl-services.png)
* **NodePort Access:** ![K8s NodePort](./Container-Assessment/evidence/09-k8s-nodeport.png)

### Application Health & Access
* **Health Endpoint:** ![App Health](./Container-Assessment/evidence/10-k8s-application-health.png)
* **Browser Access:** ![App Access](./Container-Assessment/evidence/11-k8s-application-access.png)
