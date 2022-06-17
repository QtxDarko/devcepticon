terraform {
  cloud {
    organization = "sferatechnologies"
    workspaces {
      tags = [
        "eks",
        "sferatech-v2-add-ons"
      ]
    }
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }

    helm = {}

    kubernetes = {}

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}
