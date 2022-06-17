locals {
  cluster_name    = format("%s-%s", var.cluster_config.cluster_name_prefix, var.environment)
  cluster_version = var.cluster_config.kubernetes_version
  region          = var.cluster_config.aws_region

  tags = {
    Name                                                   = local.cluster_name
    Env                                                    = "dev"
    format("kubernetes.io/cluster/%s", local.cluster_name) = "owned"
  }

  tags_k8s = {
    format("kubernetes.io/cluster/%s", local.cluster_name) = "owned"
  }
}
