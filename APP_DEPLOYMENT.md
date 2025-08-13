


### How to deploy boot-chart app in Kubernetes cluster


```bash
git clone https://github.com/andreixmartins/boot-chart
cd boot-chart
helm install boot-chart ./boot-chart -n app
kubectl port-forward svc/boot-chart -n app 8282:8282
```

