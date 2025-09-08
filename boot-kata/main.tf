
variable "kubeconfig_for_providers" {
  type    = string
  default = "kata-cluster-config"
}

resource "kind_cluster" "dev" {
  name           = var.cluster_name
  wait_for_ready = true

  kind_config {
    api_version = "kind.x-k8s.io/v1alpha4"
    kind        = "Cluster"
    node {
      role = "control-plane"

      # Map host ports to the NodePorts we'll pin in the Helm install
      extra_port_mappings {
        container_port = 31447  # HTTP NodePort in cluster
        host_port      = 8090   # host port you'll curl
        protocol       = "TCP"
      }
      extra_port_mappings {
        container_port = 31448  # HTTPS NodePort in cluster
        host_port      = 8453   # host port you'll curl for TLS tests
        protocol       = "TCP"
      }
    }
  }

}


# Providers
provider "kind" {
  
}

provider "kubernetes" {
  config_path = var.kubeconfig_for_providers
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_for_providers
  }  
}


# Namespaces
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

resource "kubernetes_namespace" "namespace_argocd" {
  metadata { name = "argocd" }
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
      app = "jenkins_infra"
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
  depends_on = [helm_release.kps]
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


# --- Argo CD via Helm ---
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.8.3"
  namespace  = kubernetes_namespace.namespace_argocd.metadata[0].name
  wait       = true
  timeout    = 600

  values     = [file("${path.module}/helm-values/argocd-repo-values.yaml")]

  depends_on = [kubernetes_namespace.namespace_argocd]
}

# --- Initial admin password output ---
data "kubernetes_secret" "argocd_admin" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = kubernetes_namespace.namespace_argocd.metadata[0].name
  }
  depends_on = [helm_release.argocd]
}


# API GATEWAY
# Using releases/latest so you always get the GA Standard channel definitions.
data "http" "gateway_api_standard" {
  url = "https://github.com/kubernetes-sigs/gateway-api/releases/latest/download/standard-install.yaml"
}

data "kubectl_file_documents" "gateway_api_docs" {
  content = data.http.gateway_api_standard.response_body
}

resource "kubectl_manifest" "gateway_api" {
  for_each  = data.kubectl_file_documents.gateway_api_docs.manifests
  yaml_body = each.value
}

# Install NGF via the Helm provider with NodePort + fixed nodePorts
# The chart is published in an OCI registry (ghcr.io).
resource "helm_release" "ngf" {
  name             = "ngf"
  namespace        = "nginx-gateway"
  create_namespace = true

  repository = "oci://ghcr.io/nginx/charts"
  chart      = "nginx-gateway-fabric"

  # Wait up to 10m for the deployment to roll out
  timeout = 600
  wait    = true

  # Provide values as YAML so we can set complex structures cleanly:
  values = [yamlencode({
    nginx = {
      service = {
        type      = "NodePort"
        # Pin the NodePorts to match our kind host port mappings
        nodePorts = [
          { port = 31447, listenerPort = 80  },
          { port = 31448, listenerPort = 443 },
        ]
      }
    }
  })]

  depends_on = [kubectl_manifest.gateway_api]
}


# ---- GatewayClass (Envoy Gateway) ----
# Equivalent to:
# apiVersion: gateway.networking.k8s.io/v1
# kind: GatewayClass
# metadata:
#   name: envoy-gateway-class
# spec:
#   controllerName: gateway.envoyproxy.io/gatewayclass-controller
resource "kubectl_manifest" "envoy_gateway_class" {
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata   = { name = "envoy-gateway-class" }
    spec       = {
      controllerName = "gateway.envoyproxy.io/gatewayclass-controller"
    }
  })
  depends_on = [helm_release.ngf]
}

# Envoy Gateway
# Equivalent to helm install eg oci://docker.io/envoyproxy/gateway-helm --version v1.5.0 -n envoy-gateway-system --create-namespace
resource "helm_release" "envoy_gateway" {
  name             = "eg"
  namespace        = "envoy-gateway-system"
  create_namespace = true

  repository = "oci://registry-1.docker.io/envoyproxy"
  chart      = "gateway-helm"
  version    = "v1.5.0"

  repository_username = var.dockerhub_username
  repository_password = var.dockerhub_token

  wait    = true
  timeout = 600
  depends_on = [kubectl_manifest.envoy_gateway_class]
}