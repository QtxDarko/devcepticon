output "aws_auth_configmap_yaml" {
  value = module.eks.aws_auth_configmap_yaml
}

output "eks_managed_node_groups" {
  value = module.eks.eks_managed_node_groups
}

output "eks_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
}
