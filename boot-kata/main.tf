
resource "kind_cluster" "this" {
  name           = var.cluster_name
  wait_for_ready = true
  # kubeconfig_path      = "${path.module}/kubeconfig.yaml"

  # kind_config {
  #   api_version = "kind.x-k8s.io/v1alpha4"
  #   kind        = "Cluster"
  #   node {
  #     role = "control-plane"

  #     # Map host ports to the NodePorts we'll pin in the Helm install
  #     extra_port_mappings {
  #       container_port = 31437  # HTTP NodePort in cluster
  #       host_port      = 8080   # host port you'll curl
  #       protocol       = "TCP"
  #     }
  #     extra_port_mappings {
  #       container_port = 31438  # HTTPS NodePort in cluster
  #       host_port      = 8443   # host port you'll curl for TLS tests
  #       protocol       = "TCP"
  #     }
  #   }
  # }

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

provider "kubectl" {
  config_path       = local_file.kubeconfig.filename
  load_config_file  = true
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

# Ingress

# resource "helm_release" "ingress_nginx" {
#   name             = "ingress-nginx"
#   repository       = "https://kubernetes.github.io/ingress-nginx"
#   chart            = "ingress-nginx"
#   namespace        = "ingress-nginx"
#   create_namespace = true
#   # version        = "x.y.z" # (optional but recommended to pin)

#   # --set controller.ingressClassResource.name=nginx
#   set {
#     name  = "controller.ingressClassResource.name"
#     value = "nginx"
#   }

#   # --set controller.ingressClass=nginx
#   set {
#     name  = "controller.ingressClass"
#     value = "nginx"
#   }

#   # --set controller.publishService.enabled=false
#   # kind doesn’t have real LoadBalancer Services. With NodePort exposure, there’s no external LB address to publish, so turn this off to avoid unnecessary lookups/warnings.
#   set {
#     name  = "controller.publishService.enabled"
#     value = "false"
#   }

#   # --set controller.service.type=NodePort
#   # kind can’t provision cloud LBs. NodePort works locally and can be mapped to host ports via kind’s extraPortMappings.
#   set {
#     name  = "controller.service.type"
#     value = "NodePort"
#   }


# # Fix the exact NodePort numbers for HTTP/HTTPS.
# # Why (kind): You’ll map these container ports to your host (e.g., host 80→30080, 443→30443). 
# # If you don’t fix them, Kubernetes picks random NodePorts (30000–32767), and your host-port mappings won’t line up.
#   # --set controller.service.nodePorts.http=30080
#   set {
#     name  = "controller.service.nodePorts.http"
#     value = "30088"
#   }

#   # --set controller.service.nodePorts.https=30443
#   set {
#     name  = "controller.service.nodePorts.https"
#     value = "30553"
#   }
# }



# API GATEWAY
# Using releases/latest so you always get the GA Standard channel definitions.
# data "http" "gateway_api_standard" {
#   url = "https://github.com/kubernetes-sigs/gateway-api/releases/latest/download/standard-install.yaml"
# }

# data "kubectl_file_documents" "gateway_api_docs" {
#   content = data.http.gateway_api_standard.response_body
# }

# resource "kubectl_manifest" "gateway_api" {
#   for_each  = data.kubectl_file_documents.gateway_api_docs.manifests
#   yaml_body = each.value
# }

# # Install NGF via the Helm provider with NodePort + fixed nodePorts
# # The chart is published in an OCI registry (ghcr.io).
# resource "helm_release" "ngf" {
#   name             = "ngf"
#   namespace        = "nginx-gateway"
#   create_namespace = true

#   repository = "oci://ghcr.io/nginx/charts"
#   chart      = "nginx-gateway-fabric"

#   # Wait up to 10m for the deployment to roll out
#   timeout = 600
#   wait    = true

#   # Provide values as YAML so we can set complex structures cleanly:
#   values = [yamlencode({
#     nginx = {
#       service = {
#         type      = "NodePort"
#         # Pin the NodePorts to match our kind host port mappings
#         nodePorts = [
#           { port = 31437, listenerPort = 80  },
#           { port = 31438, listenerPort = 443 },
#         ]
#       }
#     }
#   })]

#   depends_on = [kubectl_manifest.gateway_api]
# }