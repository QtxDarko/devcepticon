/*
module "iam_assumable_role_admin" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "4.13.1"

  number_of_role_policy_arns = 1
  create_role                = true
  role_name                  = format("efs-csi-%s", local.cluster_name)
  provider_url               = data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
  role_policy_arns = [
    aws_iam_policy.policy_efs_csi.arn
  ]
  oidc_fully_qualified_subjects = [
    # format("system:serviceaccount:%s:efs-csi-controller-sa", local.cluster_name)
    "system:serviceaccount:kube-system:efs-csi-controller-sa"
  ]
  tags = {
    EksCluster  = local.cluster_name
    Environment = var.environment
  }
}
*/

/*
resource "kubernetes_service_account" "service_account_efs_csi" {
  metadata {
    name = "efs-csi-controller-sa"
    labels = {
      "app.kubernetes.io/name" = "aws-efs-csi-driver"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = format("arn:aws:iam::%s:role/%s", local.account_id, aws_iam_role.efs_csi_role.name)
    }

    namespace = "kube-system"
  }

  depends_on = [
    kubectl_manifest.aws-auth
  ]
}

resource "helm_release" "efs_csi_driver" {
  name       = "aws-efs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  chart      = "aws-efs-csi-driver"
  namespace  = "kube-system"

  set {
    name  = "image.repository"
    value = format("602401143452.dkr.ecr.%s.amazonaws.com/eks/aws-efs-csi-driver", var.aws_region)
  }

  set {
    name  = "controller.serviceAccount.create"
    value = "false"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "efs-csi-controller-sa"
  }

  depends_on = [
    kubernetes_service_account.service_account_efs_csi
  ]
}

resource "aws_security_group" "sg_efs_csi" {
  name        = format("efs-csi-%s", local.cluster_name)
  description = "Allows access to EFS"
  vpc_id      = join("", data.aws_vpcs.public.ids)

  ingress {
    description = "NFS Access"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [
      local.cidr_subnet
    ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_efs_file_system" "efs_shared_storage" {
  creation_token = local.cluster_name

  tags = {
    name = format("efs-csi-%s", local.cluster_name)
  }

  depends_on = [
    helm_release.efs_csi_driver
  ]
}

resource "aws_efs_mount_target" "mount_target" {
  for_each = data.aws_subnet_ids.public.ids

  file_system_id = aws_efs_file_system.efs_shared_storage.id
  subnet_id      = each.key
  security_groups = concat(
    data.aws_security_groups.sg_default.ids,
    [
      aws_security_group.sg_efs_csi.id
    ]
  )
}

resource "kubernetes_storage_class" "sc_efs" {
  metadata {
    name = "sc-efs-csi"
  }
  storage_provisioner = "efs.csi.aws.com"
  reclaim_policy      = "Delete"
  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = aws_efs_file_system.efs_shared_storage.id
    directoryPerms   = "700"
  }

  depends_on = [
    aws_efs_mount_target.mount_target,
    kubernetes_service_account.service_account_efs_csi
  ]
}
*/
