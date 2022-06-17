resource "kubernetes_namespace" "k8s-dashboard" {
  metadata {
    name = "kubernetes-dashboard"
  }

  depends_on = [
    kubectl_manifest.aws-auth
  ]
}

resource "helm_release" "kubernetes-dashboard" {
  name       = "kubernetes-dashboard"
  repository = "https://kubernetes.github.io/dashboard/"
  chart      = "kubernetes-dashboard"
  namespace  = kubernetes_namespace.k8s-dashboard.metadata[0].name

  set {
    name  = "protocolHttp"
    value = "true"
  }

  set {
    name  = "rbac.clusterReadOnlyRole"
    value = "true"
  }
}
