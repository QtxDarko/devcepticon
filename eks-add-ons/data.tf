data "aws_caller_identity" "current" {}

data "aws_vpcs" "public" {
  tags = {
    Scope = "Public"
  }
}

data "aws_vpc" "public" {
  id = local.vpc_id
}

data "aws_subnet_ids" "public" {
  vpc_id = local.vpc_id
}

data "aws_security_groups" "sg_default" {
  filter {
    name = "vpc-id"
    values = [
      join("", data.aws_vpcs.public.ids)
    ]
  }

  filter {
    name = "group-name"
    values = [
      "default"
    ]
  }
}

data "aws_eks_cluster" "eks_cluster" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "eks_cluster" {
  name = local.cluster_name
}

data "aws_acm_certificate" "prometheus_server" {
  domain   = local.prometheus_server_hostname
  statuses = ["ISSUED"]
}

# data "aws_route53_zone" "zone" {
#   name = var.domain_name
# }

data "aws_iam_roles" "eks_ng_roles" {
  name_regex = format("ng-%s.*", local.cluster_name)
}

data "aws_iam_policy_document" "ng_iam_role_policy_ecs_discovery" {
  statement {
    sid    = "NgIamRolePolicyEcsDiscovery"
    effect = "Allow"
    actions = [
      "ECS:ListClusters",
      "ECS:ListTasks",
      "ECS:DescribeTask*",
      "EC2:DescribeInstances",
      "ECS:DescribeContainerInstances",
      "ECS:DescribeClusters"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "AllowReadWriteToTable"
    effect = "Allow"
    actions = [
      "timestream:WriteRecords",
      "timestream:Select"
    ]
    resources = [
      "arn:aws:timestream:${var.aws_region}:${local.account_id}:database/db-prometheus/table/tbl-prometheus"
    ]
  }

  statement {
    sid    = "AllowDescribeEndpoints"
    effect = "Allow"
    actions = [
      "timestream:DescribeEndpoints"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "AllowValueRead"
    effect = "Allow"
    actions = [
      "timestream:SelectValues"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "AllowListMeasures"
    effect = "Allow"
    actions = [
      "timestream:ListMeasures"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "policy_document_efs_csi_assume" {
  statement {
    sid    = "EfsCsiAss1"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type = "Federated"
      identifiers = [
        format("arn:aws:iam::%s:oidc-provider/%s", local.account_id, local.oidc_id)
      ]
    }
    condition {
      test     = "StringEquals"
      variable = local.oidc_id
      values = [
        "system:serviceaccount:kube-system:efs-csi-controller-sa"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = local.oidc_id_aud
      values = [
        "sts:amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "policy_document_efs_csi" {
  statement {
    sid    = "EfsCsi1"
    effect = "Allow"
    actions = [
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "EfsCsi2"
    effect = "Allow"
    actions = [
      "elasticfilesystem:CreateAccessPoint"
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/efs.csi.aws.com/cluster"
      values = [
        "true"
      ]
    }
  }

  statement {
    sid    = "EfsCsi3"
    effect = "Allow"
    actions = [
      "elasticfilesystem:DeleteAccessPoint"
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/efs.csi.aws.com/cluster"
      values = [
        "true"
      ]
    }
  }
}
