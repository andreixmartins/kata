

# Kata cluster

Create a Kubernetes cluster using helm charts and tofu scripts. To build the Kubernetes cluster install the following tools

## Requirements
- Docker/Podman
- Minikube
- OpenTofu
- You need at least 8GB of memory provisioned in Docker


## Installation 

Run the commands bellow to create the cluster

- Build cluster
```bash
tofu init
tofu apply -auto-approve
```

Run the commands bellow to destroy the cluster

- Destroy cluster
```bash
tofu destroy -auto-approve
```

# Docker commands

- To build jenkins Docker image
docker build -t axsoftware/jenkins-agent .

- To build jenkins Docker image in arm64 ARCH
docker buildx build --platform linux/arm64 -t axsoftware/jenkins-agent .

- Publishing jenkins images to Dockerhub
docker push axsoftware/jenkins-agent:latest

# Kubectl commands

- Delete minikube cluster manually
kind delete cluster --name kata-cluster || true


# ArgoCD commands 

helm upgrade  argocd argo/argo-cd -n argocd -f /boot-kata/helm-values/argocd-values.yaml

helm upgrade  argocd argo/argo-cd -n argocd -f ./helm-values/argocd-values.yaml
