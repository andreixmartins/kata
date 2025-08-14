#!/usr/bin/env bash

echo "Installing Minikube" 
brew install minikube
brew install kubernetes-cli
minikube config set driver docker
minikube addons enable ingress
minikube stop
minikube delete && minikube start --driver=docker --cpus=4 --memory=8192
minikube ssh -- nproc
minikube ssh -- grep MemTotal /proc/meminfo

echo "Creating namespaces infra and app" 
kubectl create namespace infra
kubectl create namespace app
