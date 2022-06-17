resource "kubectl_manifest" "aws-auth" {
  yaml_body = <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
%{for eks_ng_iam_role_arn in local.eks_ng_iam_role_arns~}
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: ${eks_ng_iam_role_arn}
      username: system:node:{{EC2PrivateDNSName}}
%{endfor~}
%{for eks_cluster_user in var.eks_cluster_users~}
    - groups:
      - system:masters
      rolearn: arn:aws:iam::${local.account_id}:user/${eks_cluster_user}
      username: ${eks_cluster_user}
%{endfor~}
YAML
}
