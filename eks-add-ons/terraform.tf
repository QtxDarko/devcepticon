terraform {
  cloud {
    organization = "example-org-e3ac34"
    workspaces {
      tags = [
        "eks-add-ons"
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
