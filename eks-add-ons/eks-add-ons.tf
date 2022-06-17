module "eks-ssp-kubernetes-addons" {
  # source = "./modules/kubernetes-addons"
  source = "github.com/aws-samples/aws-eks-accelerator-for-terraform//modules/kubernetes-addons"
  # source = "github.com/dlxmedia/terraform-modules.git//modules/eks-ssp-kubernetes-addons/modules/kubernetes-addons"

  eks_cluster_id = data.aws_eks_cluster.eks_cluster.id

  # EKS Addons
  # enable_amazon_eks_vpc_cni            = true
  # enable_amazon_eks_coredns            = true
  # enable_amazon_eks_kube_proxy         = true
  # enable_amazon_eks_aws_ebs_csi_driver = true

  # K8s Add-ons
  # enable_aws_load_balancer_controller = true
  enable_metrics_server = true
  metrics_server_helm_config = {
    values = [templatefile("${path.module}/helm_values/metrics-server-values.yaml", {
      operating_system = "linux"
    })]
  }
  enable_cluster_autoscaler = true
  # enable_aws_node_termination_handler = true
  # enable_aws_for_fluentbit            = true
  # enable_argocd                       = true
  # enable_ingress_nginx                = true

  depends_on = [
    kubectl_manifest.aws-auth
  ]
}

resource "kubernetes_service_account" "service_account_aws_lb_ctrl" {
  metadata {
    name = "aws-load-balancer-controller"
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = format("arn:aws:iam::%s:role/%s", local.account_id, aws_iam_role.aws_lb_ctrl_role.name)
    }

    namespace = "kube-system"
  }

  depends_on = [
    kubectl_manifest.aws-auth
  ]
}

resource "helm_release" "aws-lb-ctrl" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = local.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.service_account_aws_lb_ctrl.metadata[0].name
  }
}
