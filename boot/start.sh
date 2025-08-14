#!/usr/bin/env bash

docker info >/dev/null 2>&1 && echo "Docker engine is RUNNING" || echo "Docker engine is NOT reachable"

# OpenTofu
echo "Installing Opentofu" 
brew update
brew install opentofu
tofu -version


# Minikube
echo "Installing Minikube" 
brew install minikube
brew install kubernetes-cli
minikube config set driver docker
minikube addons enable ingress
minikube stop
minikube delete && minikube start --driver=docker --cpus=4 --memory=8192
minikube ssh -- nproc
minikube ssh -- grep MemTotal /proc/meminfo

# Helm
echo "Installing HELM" 
brew install helm
helm version


# Spring Boot app
echo "Creating Boot Chart app job"
helm repo add ax https://andreixmartins.github.io/helm-charts
helm repo update
helm install boot-chart andrei/boot-chart -n app --create-namespace


# Jenkins installation
echo "Installing HELM Jenkins" 
helm repo add jenkins https://charts.jenkins.io
helm repo update
helm install jenkins jenkins/jenkins -n infra  --create-namespace


# Prometheus
echo "Installing Prometheus" 
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n infra -f prometheus-values.yaml  --create-namespace


# Check if all pods are running
./check-all-pods-running.sh --watch


# Port port-forward
echo "Grafana Port forwarding :3000" 
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80

echo "Grafana password" 
kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo

echo "Boot chart forwarding :8282" 
kubectl -n app port-forward svc/boot-chart 8282:8282

echo "Jenkins port forwarding"
kubectl port-forward svc/jenkins --namespace infra 8080:8080


# Jenkins pipeline
echo "Creating Jenkins pipeline" 
JENKINS_URL=http://localhost:8080
USER=admin
PASS=admin

CRUMB=$(curl -s -u "$USER:$PASS" --cookie-jar cookies.txt "$JENKINS_URL/crumbIssuer/api/json" | jq -r '.crumbRequestField+":"+.crumb')
TOKEN_DATA=$(curl -s -u "$USER:$PASS" --cookie cookies.txt -H "$CRUMB" -X POST "$JENKINS_URL/user/$USER/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken" --data 'newTokenName=cli')
TOKEN=$(jq -r '.data.tokenValue' <<<"$TOKEN_DATA")
CRUMB=$(curl -s -u "$USER:$TOKEN" "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")
curl -u "$USER:$TOKEN" -H "Content-Type: application/xml" --data-binary @boot-chart-job.xml "$JENKINS_URL/createItem?name=boot-chart-job"

echo "Creating Jenkins credentials"
curl -u "$USER:$TOKEN" -H 'Content-Type: application/xml' ${CRUMB:+-H "$CRUMB"} --data-binary @dockerhub-creds.xml "$JENKINS_URL/credentials/store/system/domain/_/createCredentials"

echo "Trigger job" 
# curl -u "$USER:$TOKEN" -X POST "$JENKINS_URL/job/boot-chart-job/build"


