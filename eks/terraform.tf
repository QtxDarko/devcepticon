terraform {
  cloud {
    organization = "example-org-e3ac34"
    workspaces {
      tags = [
        "test-eks"
      ]
    }
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
