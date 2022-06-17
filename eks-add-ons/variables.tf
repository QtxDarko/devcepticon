variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-central-1"
}

variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = "sferatechnologies.com"
}

variable "environment" {
  description = "Environment: prod/dev/stag"
  type        = string
  default     = "dev"
}

variable "cluster_name_prefix" {
  description = "EKS cluster name prefix"
  type        = string
  default     = "sferatech-v2"
}

variable "ebs_storage_size" {
  description = "EBS storage size"
  type        = string
  default     = "200Gi"
}

variable "efs_storage_size" {
  description = "EBS storage size"
  type        = string
  default     = "10Gi"
}

variable "eks_cluster_users" {
  description = "EKS Cluster Users"
  type        = list(string)
  default = [
    "sferatech-terraform",
    "morpheus",
    "gjorgjit"
  ]
}

variable "enable_timestream" {
  description = "Enable timestream"
  type        = bool
  default     = false
}

variable "ecs_discovery_image" {
  description = "ECS discovery image"
  type        = string
  default     = "prometheus-ecs-discovery:latest"
}

variable "ecs_cluster_name_prefix" {
  description = "ECS cluster name prefix"
  type        = string
  default     = "sferatech"
}

variable "ecs_scan_interval" {
  description = "ECS scan interval"
  type        = string
  default     = "60"
}

variable "ecs_file_sd" {
  description = "YAML file to store scan result"
  type        = string
  default     = "/mnt/ecs_file_sd.yml"
}

variable "istio_config" {
  description = "Istio config"
  type        = any
  default = {
    create    = false
    namespace = "istio-system"
    ingress = {
      create    = false
      namespace = "istio-ingress"
      manifest = {
        create = false
      }
      gateway = {
        create = false
      }
    }
  }
}