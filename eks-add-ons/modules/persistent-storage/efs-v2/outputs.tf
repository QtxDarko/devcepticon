output "pvc_name" {
  value = kubernetes_persistent_volume_claim.pvc_prometheus.metadata[0].name
}
