terraform {
  required_version = ">= 1.3.2"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.15"
    }
  }
}
