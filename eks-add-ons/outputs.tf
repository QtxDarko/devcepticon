output "eks_ng_iam_role_arns" {
  value = local.eks_ng_iam_role_arns
}

output "eks_ng_iam_role_names" {
  value = local.eks_ng_iam_role_names
}

output "eks_oidc_issuer_url" {
  value = data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

# output "efs_shared_storage" {
#   value = aws_efs_file_system.efs_shared_storage
# }

output "cidr_subnet" {
  value = local.cidr_subnet
}

output "subnet_ids" {
  value = data.aws_subnet_ids.public.ids
}

# output "prometheus_server_ingress" {
#   value = kubernetes_ingress.prometheus_server.status[0].load_balancer[0].ingress[0].hostname
# }