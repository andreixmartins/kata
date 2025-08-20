

# Docker hub credential for Jenkins pipeline
resource "kubernetes_secret" "dockerhub" {
  metadata {
    name      = "jenkins-dockerhub"
    namespace = "infra"
  }

  data = {
    username = var.dockerhub_username
    token    = var.dockerhub_token
  }

  type = "Opaque"
}

# Jenkins admin credential to acess Jenkins on port 8080
resource "kubernetes_secret" "jenkins_admin" {
  metadata {
    name      = "jenkins-admin"
    namespace = "infra"
  }

  data = {
    username = "admin"
    password = var.jenkins_admin_password
  }

  type = "Opaque"
}




