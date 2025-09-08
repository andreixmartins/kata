

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
# Initialize tf environment
tofu init
# Start kind cluster
tofu apply -auto-approve -target=kind_cluster.dev
# Start cluster structure using binding kubeconfig variable
tofu apply -auto-approve -var "kubeconfig_for_providers=kata-cluster-config"
```

Run the commands bellow to destroy the cluster

- Destroy cluster
```bash
# Destroy kind cluster
tofu destroy -auto-approve -target=kind_cluster.dev
# Destroy cluster structure
tofu destroy -auto-approve -var "kubeconfig_for_providers=kata-cluster-config"
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



# DEMO APP - Gateway test

- Check demo app
```bash
kubectl apply -f ./gateway/envoy-gateway-class.yaml
kubectl -n demo describe gateway demo-gw
kubectl -n demo get gateway demo-gw -o wide
``` 

- Port forwarding to access demo app
```bash 
SVC=$(kubectl -n envoy-gateway-system get svc -l "gateway.envoyproxy.io/owning-gateway-namespace=demo,gateway.envoyproxy.io/owning-gateway-name=demo-gw" -o jsonpath='{.items[0].metadata.name}')

kubectl -n envoy-gateway-system port-forward service/$SVC 8080:80
# new terminal:
curl -i http://127.0.0.1:8080/

```


# DEMO BOOT-CHART APP - Gateway test


```bash 
kubectl apply -f ./boot-kata/gateway/boot-chart-gateway.yaml

SVC=$(kubectl -n envoy-gateway-system get svc -l "gateway.envoyproxy.io/owning-gateway-namespace=app,gateway.envoyproxy.io/owning-gateway-name=boot-chart" -o jsonpath='{.items[0].metadata.name}')

kubectl -n envoy-gateway-system port-forward service/$SVC 8080:8282
```

