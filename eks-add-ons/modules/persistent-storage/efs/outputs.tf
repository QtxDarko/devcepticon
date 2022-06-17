output "pvc_name" {
  value = {
    static  = try(kubernetes_persistent_volume_claim.pvc_prometheus_component[0].metadata[0].name, "")
    dynamic = try(kubernetes_persistent_volume_claim.pvc_prometheus_component_dynamic[0].metadata[0].name, "")
  }
}
