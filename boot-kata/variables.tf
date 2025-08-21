# Kubernetes cluster name
variable "cluster_name" {
  type    = string
  default = "kata-cluster"
}

# Docker hub username for publishing docker image to dockerhub
variable "dockerhub_username" {
  type        = string
}

# Dockerhub registry token. You should get it in your Dockerhub admin account
variable "dockerhub_token" {
  type        = string
  sensitive   = true
}

# Default Jenkins password to acess Jenkin on http://localhost:8080
variable "jenkins_admin_password" {
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "kube_context"        { 
  type = string
  default = null 
}
variable "server_service_type" { 
  type = string 
  default = "ClusterIP" 
}
variable "chart_version"       { 
  type = string 
  default = "7.8.3" 
} 
