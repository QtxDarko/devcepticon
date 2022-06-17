resource "kubernetes_persistent_volume" "pv_prometheus" {
  metadata {
    name = format("pv-%s", var.pv_name_suffix)
  }
  spec {
    capacity = {
      storage = var.capacity_storage
    }
    volume_mode                      = var.volume_mode
    access_modes                     = var.access_modes
    persistent_volume_reclaim_policy = var.persistent_volume_reclaim_policy
    storage_class_name               = var.storage_class_name
    persistent_volume_source {
      csi {
        driver        = var.csi_driver
        volume_handle = var.file_system_id
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "pvc_prometheus" {
  metadata {
    name = format("pvc-%s", var.pv_name_suffix)
  }
  spec {
    resources {
      requests = {
        storage = var.pvc_storage_size
      }
    }
    access_modes       = var.access_modes
    storage_class_name = var.storage_class_name
    volume_name        = kubernetes_persistent_volume.pv_prometheus.metadata[0].name
  }
}
