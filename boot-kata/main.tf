# Create a local kind cluster
resource "kind_cluster" "this" {
  name           = var.cluster_name
  wait_for_ready = true
}

# Create kubeconfig for providers/CLI
resource "local_file" "kubeconfig" {
  content  = kind_cluster.this.kubeconfig
  filename = "${path.module}/kubeconfig.yaml"
}

# Kubernetes and Helm providers wired to the cluster
provider "kubernetes" {
  config_path = local_file.kubeconfig.filename
}

provider "helm" {
  kubernetes {
    config_path = local_file.kubeconfig.filename
  }
}

resource "kubernetes_namespace" "namespace_app" {
  metadata {
    name = "app"
  }
}

resource "kubernetes_namespace" "namespace_infra" {
  metadata {
    name = "infra"
  }
}


resource "kubernetes_service_account" "jenkins_service_account" {
  metadata {
    name      = "jenkins-service-account"
    namespace = "infra"
  }
}

resource "kubernetes_cluster_role" "jenkins_cluster_admin" {
  metadata {
    name = "jenkins-cluster-admin"
    labels = {
      app = "Jenkins infra"
    }
  }

  # Core API ("" = core group) 
  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_cluster_role_binding" "jenkins_cluster_admin_binding" {
  metadata {
    name = "jenkins-cluster-admin-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.jenkins_cluster_admin.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.jenkins_service_account.metadata[0].name
    namespace = kubernetes_service_account.jenkins_service_account.metadata[0].namespace
  }
}


# Spring Boot example app
resource "helm_release" "boot_chart" {
  name             = "boot-chart"
  repository       = "https://andreixmartins.github.io/helm-charts"
  chart            = "boot-chart"
  namespace        = "app"
  create_namespace = true
  wait             = true
  timeout          = 900
}

# Jenkins
resource "helm_release" "jenkins" {
  name             = "jenkins"
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  namespace        = "infra"
  create_namespace = true
  wait             = true
  timeout          = 1800
  values           = [file("${path.module}/helm-values/jenkins-values.yaml")]
}

# Prometheus Stack
resource "helm_release" "kps" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "infra"
  create_namespace = true
  wait             = true
  timeout          = 1800
  values           = [file("${path.module}/helm-values/prometheus-values.yaml")]
}

# TODO - Remove it later
# Wait for app pods to be ready
resource "null_resource" "wait_app" {
  depends_on = [helm_release.boot_chart]
  provisioner "local-exec" {
    command = "kubectl --kubeconfig=${local_file.kubeconfig.filename} wait -n app --for=condition=Ready pod --all --timeout=600s || true"
  }
}