/*
# ###############################
# # Resizable storage class
# ###############################

resource "kubernetes_storage_class" "sc_ebs" {
  metadata {
    name = format("sc-ebs-%s", local.cluster_name)
  }
  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Retain"

  depends_on = [
    module.eks-ssp-kubernetes-addons
  ]
}

# ###############################
# # PVC
# ###############################
resource "kubernetes_persistent_volume_claim" "pvc_ebs" {
  metadata {
    name = format("pvc-%s", local.cluster_name)
    # namespace = kubernetes_namespace.prometheus.metadata[0].name
  }
  spec {
    resources {
      requests = {
        storage = var.ebs_storage_size
      }
    }
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = kubernetes_storage_class.sc_ebs.metadata[0].name
  }
}
*/
