#!/usr/bin/env bash

echo "Installing HELM" 
brew install helm
helm version

echo "Installing HELM Jenkins" 
helm repo add jenkins https://charts.jenkins.io
helm repo update
helm install jenkins jenkins/jenkins -n infra
kubectl get secret --namespace infra jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
kubectl port-forward svc/jenkins --namespace infra 8080:8080
