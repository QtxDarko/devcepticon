variable "environment" {
  description = "Environment: prod/dev/stag"
  type        = string
  default     = "dev"
}

variable "cluster_config" {
  description = "Cluster config"
  type        = any
  default = {
    access_from_bastion = true
    aws_region          = "eu-central-1"
    cluster_name_prefix = "sferatech-v2"
    kubernetes_version  = "1.22"
    workers = {
      key_name    = "remote_access"
      disk_size   = 50
      volume_type = "gp3"
      instance_types = [
        "t2.medium"
      ]
      autoscaling_group = {
        min_size     = 1
        max_size     = 10
        desired_size = 1
      }
    }
    istio_config = {
      create    = true
      namespace = "istio-system"
      ingress = {
        create    = true
        namespace = "istio-ingress"
      }
    }
  }
}