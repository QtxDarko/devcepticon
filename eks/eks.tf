module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.5.0"

  cluster_name                    = local.cluster_name
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  # IPV6
  # cluster_ip_family          = "ipv6"
  # create_cni_ipv6_iam_policy = true
  cluster_ip_family = "ipv4"

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  #   cluster_encryption_config = [{
  #     provider_key_arn = aws_kms_key.eks.arn
  #     resources        = ["secrets"]
  #   }]

  vpc_id     = join("", data.aws_vpcs.public.ids)
  subnet_ids = data.aws_subnet_ids.public.ids

  cluster_enabled_log_types = ["api", "authenticator"]
  enable_irsa               = true

  /*
  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }
  */

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    disk_size      = var.cluster_config.workers.disk_size
    instance_types = var.cluster_config.workers.instance_types
  }

  eks_managed_node_groups = {
    # Default node group - as provided by AWS EKS
    default_node_group = {
      name            = format("ng-%s", local.cluster_name)
      use_name_prefix = true

      create_launch_template = false
      launch_template_name   = aws_launch_template.eks_managed_node_group_custom_launch_template.name

      subnet_ids = data.aws_subnet_ids.public.ids

      min_size     = var.cluster_config.workers.autoscaling_group.min_size
      max_size     = var.cluster_config.workers.autoscaling_group.max_size
      desired_size = var.cluster_config.workers.autoscaling_group.desired_size

      instance_types = var.cluster_config.workers.instance_types
      capacity_type  = "SPOT"
      labels = {
        Env = "dev"
      }
    }
  }

  /*
  # No custom launch template
  eks_managed_node_groups = {
    # Default node group - as provided by AWS EKS
    default_node_group = {
      name            = format("%s", local.cluster_name)
      use_name_prefix = true

      create_launch_template = false
      launch_template_name   = ""

      remote_access = {
        ec2_ssh_key               = "remote_access"
        source_security_group_ids = [aws_security_group.remote_access.id]
      }

      subnet_ids = data.aws_subnet_ids.public.ids

      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t2.medium"]
      capacity_type  = "SPOT"
      disk_size      = 50
      labels = {
        Env = "dev"
      }
    }
  }
  */

  tags = local.tags

  # depends_on = [
  #   aws_security_group.remote_access
  # ]
}
