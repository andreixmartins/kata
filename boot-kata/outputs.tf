output "kubeconfig" {
  value = local_file.kubeconfig.filename
}
output "cluster_name" {
  value = var.cluster_name
}

output "app_port_forward" {
  description = "Run this command to open boot-chart app on your local 8282 port"
  value       = "kubectl port-forward -n app svc/boot-chart 8282:8282"
}

output "jenkins_agent_port_forward" {
  description = "Run this command to open Jenkins port 8080 in your local"
  value       = "kubectl port-forward -n infra svc/jenkins 8080:8080"
}

output "prometheus_port_forward" {
  description = "Run this command to open Prometheus port 9090 in your local"
  value       = "kubectl port-forward -n infra svc/kube-prometheus-stack-prometheus 9090:9090"
}

output "grafana_port_forward" {
  description = "Run this command to open Grafana port 8080 in your local"
  value       = "kubectl port-forward -n infra svc/kube-prometheus-stack-grafana 3000:80"
}



output "argocd_username"             { value = "admin" }
# output "argocd_initial_admin_passwd" { value = nonsensitive(base64decode(data.kubernetes_secret.argocd_admin.data["password"])) }
output "access_hint" {
  value = "kubectl -n argocd port-forward svc/argocd-server 8888:443"
}

output "argocd_initial_admin_passwd" {
  value = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d echo"
}