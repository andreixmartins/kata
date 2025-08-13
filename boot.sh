

# HOW to install Kubernetes cluster local


# Minikube 
brew install minikube

brew install kubernetes-cli

minikube config set driver docker

minikube addons enable ingress

minikube stop

minikube delete && minikube start --driver=docker --cpus=4 --memory=8192

minikube ssh -- nproc

minikube ssh -- grep MemTotal /proc/meminfo


# Create namespaces
kubectl create namespace infra

kubectl create namespace app


# Helm
brew install helm

helm version

#Jenkins
helm repo add jenkins https://charts.jenkins.io
helm repo update

helm install jenkins jenkins/jenkins -n infra

kubectl get secret --namespace infra jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode

kubectl port-forward svc/jenkins --namespace infra 8080:8080


