variable "file_system_id" {}
variable "uid" {}
variable "gid" {}
variable "secondary_gids" {}
variable "path" {}
variable "permissions" {}
variable "pv_name_suffix" {}
variable "capacity_storage" {}
variable "volume_mode" {}
variable "access_modes" {}
variable "persistent_volume_reclaim_policy" {}
variable "storage_class_name" {}
variable "csi_driver" {}
variable "create_pv" { default = false }
# variable "namespace" {}
variable "pvc_storage_size" {}
