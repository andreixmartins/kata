#!/usr/bin/env bash


echo "Creating Boot Chart app job"
helm repo add ax https://andreixmartins.github.io/helm-charts
helm repo update
helm install boot-chart andrei/boot-chart -n app --create-namespace
helm upgrade boot-chart andrei/boot-chart -n app

echo "Boot chart forwarding :8282" 
kubectl -n app port-forward svc/boot-chart 8282:8282
