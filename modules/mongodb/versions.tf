terraform {
  required_version = ">=1.2.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.61"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = ">= 1.11.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.2"
    }
  }
}
