terraform {
  required_version = ">= 1.3.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.15"
    }
  }
}
