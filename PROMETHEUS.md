

## PROMETHEUS HELM


### Installation

- Add the repo and update
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

- Install the chart
```bash
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n infra -f prometheus-values.yaml
```

- Access the UIs (port-forward)
```bash
# Prometheus
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090

# Grafana
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
```


### Configuration

- Grafana → Acesss http://localhost:3000 (user: admin)
- To get the password run this command below
```bash
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath='{.data.admin-password}' | base64 -d; echo
```

- Create a new Prometheus datasource using this Prometheus URL http://kube-prometheus-stack-prometheus:9090
- This is the Prothemeus URL from kubernetes cluster


