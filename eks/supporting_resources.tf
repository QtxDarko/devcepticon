/*
resource "aws_kms_key" "eks" {
  description = "EKS Secret Encryption Key"
  # deletion_window_in_days = 7
  # enable_key_rotation     = true

  tags = local.tags
}
*/

/*
resource "aws_security_group" "remote_access_bastion" {
  name_prefix = "${local.cluster_name}-bastion-access"
  description = "Allow remote access form Bastion to K8S API"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for s in data.aws_subnet.public : s.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = local.tags
}
*/

/*
data "aws_iam_policy_document" "ng_iam_role_policy" {
  statement {
    sid    = "NgIamRolePolicy1"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
      "ec2:DescribeVpcs",
      "eks:DescribeCluster"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "NgIamRolePolicy2"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:ListTagsForResource",
      "ecr:DescribeImageScanFindings"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "NgIamRolePolicy3"
    effect = "Allow"
    actions = [
      "ec2:AssignPrivateIpAddresses",
      "ec2:AttachNetworkInterface",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeInstanceTypes",
      "ec2:DetachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:UnassignPrivateIpAddresses"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "NgIamRolePolicy4"
    effect = "Allow"
    actions = [
      "ec2:CreateTags"
    ]
    resources = [
      "arn:aws:ec2:*:*:network-interface/*"
    ]
  }

  statement {
    sid    = "NgIamRolePolicy5"
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
*/

/*
data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ng_iam_instance_role" {
  name               = format("ng-iam-role-%s", local.cluster_name)
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json

  inline_policy {
    name   = format("ng-iam-policy-%s", local.cluster_name)
    policy = data.aws_iam_policy_document.ng_iam_role_policy.json
  }
}

resource "aws_iam_instance_profile" "ng_iam_instance_profile" {
  name_prefix = format("ng-iam-ip-%s", local.cluster_name)
  role        = aws_iam_role.ng_iam_instance_role.name
}
*/

# This is based on the LT that EKS would create if no custom one is specified (aws ec2 describe-launch-template-versions --launch-template-id xxx)
# there are several more options one could set but you probably dont need to modify them
# you can take the default and add your custom AMI and/or custom tags
#
# Trivia: AWS transparently creates a copy of your LaunchTemplate and actually uses that copy then for the node group. If you DONT use a custom AMI,
# then the default user-data for bootstrapping a cluster is merged in the copy.

resource "aws_launch_template" "eks_managed_node_group_custom_launch_template" {
  name_prefix            = format("lt-%s-", local.cluster_name)
  description            = "EKS managed node group custom launch template"
  update_default_version = true

  key_name = var.cluster_config.workers.key_name

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.cluster_config.workers.disk_size
      volume_type           = var.cluster_config.workers.volume_type
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = true
  }

  # vpc_security_group_ids = data.aws_security_groups.sg_default.ids

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups = concat(
      data.aws_security_groups.sg_default.ids,
      [
        # module.eks.cluster_primary_security_group_id,
        # module.eks.cluster_security_group_id,
        module.eks.node_security_group_id
      ]
    )
  }

  # if you want to use a custom AMI
  # image_id      = var.ami_id

  # If you use a custom AMI, you need to supply via user-data, the bootstrap script as EKS DOESNT merge its managed user-data then
  # you can add more than the minimum code you see in the template, e.g. install SSM agent, see https://github.com/aws/containers-roadmap/issues/593#issuecomment-577181345
  # (optionally you can use https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/cloudinit_config to render the script, example: https://github.com/terraform-aws-modules/terraform-aws-eks/pull/997#issuecomment-705286151)
  # user_data = base64encode(data.template_file.launch_template_userdata.rendered)

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.tags_k8s,
      {
        Name = format("%s-worker", local.cluster_name)
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      local.tags_k8s,
      {
        Name = format("vol-%s", local.cluster_name)
      }
    )
  }

  tag_specifications {
    resource_type = "network-interface"
    tags = merge(
      local.tags_k8s,
      {
        Name = format("eni-%s", local.cluster_name)
      }
    )
  }

  # tag_specifications {
  #   resource_type = "security-group"
  #   tags = merge(
  #     local.tags_k8s,
  #     {
  #       Name = format("sg-%s", local.cluster_name)
  #     }
  #   )
  # }

  tags = merge(
    local.tags_k8s,
    {
      ClusterName = local.cluster_name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
