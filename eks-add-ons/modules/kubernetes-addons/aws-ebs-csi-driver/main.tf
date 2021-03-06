/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

resource "aws_eks_addon" "aws_ebs_csi_driver" {
  cluster_name             = var.eks_cluster_id
  addon_name               = local.add_on_config["addon_name"]
  addon_version            = local.add_on_config["addon_version"]
  resolve_conflicts        = local.add_on_config["resolve_conflicts"]
  service_account_role_arn = local.add_on_config["service_account_role_arn"] == "" ? module.irsa_addon.irsa_iam_role_arn : local.add_on_config["service_account_role_arn"]
  tags = merge(
    var.common_tags,
    local.add_on_config["tags"],
    { "eks_addon" = "aws-ebs-csi-driver" }
  )
  depends_on = [module.irsa_addon]
}

module "irsa_addon" {
  source                            = "../../irsa"
  create_kubernetes_namespace       = false
  create_kubernetes_service_account = false
  eks_cluster_id                    = var.eks_cluster_id
  kubernetes_namespace              = local.add_on_config["namespace"]
  kubernetes_service_account        = local.add_on_config["service_account"]
  irsa_iam_policies                 = concat([aws_iam_policy.aws_ebs_csi_driver.arn], local.add_on_config["additional_iam_policies"])
  tags                              = var.common_tags
}

resource "aws_iam_policy" "aws_ebs_csi_driver" {
  description = "IAM Policy for AWS EBS CSI Driver"
  name        = "${var.eks_cluster_id}-${local.add_on_config["addon_name"]}-irsa"
  path        = var.iam_role_path
  policy      = data.aws_iam_policy_document.aws-ebs-csi-driver.json
}
