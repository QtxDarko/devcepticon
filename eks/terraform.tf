terraform {
  cloud {
    organization = "sferatechnologies"
    workspaces {
      tags = [
        "ecs",
        "sferatech"
      ]
    }
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
