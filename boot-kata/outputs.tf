output "kubeconfig" {
  value = local_file.kubeconfig.filename
}
output "cluster_name" {
  value = var.cluster_name
}


output "jenkins_agent_port_forward" {
  description = "Run this command to open Jenkins port 8080 in your local"
  value       = "kubectl port-forward -n infra svc/jenkins 8080:8080"
}

output "grafana_port_forward" {
  description = "Run this command to open Grafana port 8080 in your local"
  value       = "kubectl port-forward -n infra svc/grafana 3000:80"
}