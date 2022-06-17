resource "aws_efs_access_point" "eap" {
  file_system_id = var.file_system_id

  posix_user {
    uid            = var.uid
    gid            = var.gid
    secondary_gids = var.secondary_gids
  }

  root_directory {
    path = var.path
    creation_info {
      owner_uid   = var.uid
      owner_gid   = var.gid
      permissions = var.permissions
    }
  }
}

resource "kubernetes_persistent_volume" "pv_prometheus_component" {
  count = var.create_pv ? 1 : 0

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
        volume_handle = format("%s::%s", var.file_system_id, aws_efs_access_point.eap.id)
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "pvc_prometheus_component" {
  count = var.create_pv ? 1 : 0

  metadata {
    name      = format("pvc-%s", var.pv_name_suffix)
    # namespace = var.namespace
  }
  spec {
    resources {
      requests = {
        storage = var.pvc_storage_size
      }
    }
    access_modes       = var.access_modes
    storage_class_name = var.storage_class_name
    volume_name        = kubernetes_persistent_volume.pv_prometheus_component[0].metadata[0].name
  }
}

resource "kubernetes_persistent_volume_claim" "pvc_prometheus_component_dynamic" {
  count = var.create_pv ? 0 : 1

  metadata {
    name      = format("pvc-%s", var.pv_name_suffix)
    # namespace = var.namespace
  }
  spec {
    resources {
      requests = {
        storage = var.pvc_storage_size
      }
    }
    access_modes       = var.access_modes
    storage_class_name = var.storage_class_name
  }
}
