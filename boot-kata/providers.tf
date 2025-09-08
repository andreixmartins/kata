
#  Terraform providers required to build Kubernetes cluster in Open Tofu
terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = ">= 0.9.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    time  = { 
      source = "hashicorp/time",     
      version = "~> 0.11" 
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19.0"
    }        
  }
}