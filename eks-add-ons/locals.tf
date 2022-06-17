locals {
  account_id       = data.aws_caller_identity.current.account_id
  vpc_id           = join("", data.aws_vpcs.public.ids)
  cluster_name     = format("%s-%s", var.cluster_name_prefix, var.environment)
  ecs_cluster_name = format("%s-%s", var.ecs_cluster_name_prefix, var.environment)
  eks_ng_iam_role_arns = [
    for parts in [for arn in data.aws_iam_roles.eks_ng_roles.arns : split("/", arn)] :
    format("%s/%s", parts[0], element(parts, length(parts) - 1))
  ]
  eks_ng_iam_role_names = [
    for parts in [for arn in data.aws_iam_roles.eks_ng_roles.arns : split("/", arn)] :
    format("%s", element(parts, length(parts) - 1))
  ]
  cidr_subnet = cidrsubnet(data.aws_vpc.public.cidr_block, 4, 1)
  oidc_id     = replace(data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")
  oidc_id_aud = replace(local.oidc_id, ":sub", ":aud")

  monitoring_namespace_labels = var.istio_config.create && var.istio_config.ingress.create ? { istio-injection = "enabled" } : {}

  prometheus_server_hostname = format("prometheus-server.%s.%s", local.cluster_name, var.domain_name)
  credentials_prometheus_server = {
    # hostname = kubernetes_ingress.prometheus_server.status[0].load_balancer[0].ingress[0].hostname
    username = "admin"
    # password = random_password.prometheus_server.result
    # hostname = local.prometheus_server_hostname
  }
}
