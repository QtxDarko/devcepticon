resource "kubernetes_namespace" "istio-system" {
  count = var.istio_config.create ? 1 : 0

  metadata {
    name = var.istio_config.namespace
  }

  depends_on = [
    kubectl_manifest.aws-auth
  ]
}

resource "kubernetes_namespace" "istio-ingress" {
  count = var.istio_config.create && var.istio_config.ingress.create ? 1 : 0

  metadata {
    name = var.istio_config.ingress.namespace

    labels = {
      istio-injection = "enabled"
    }
  }

  depends_on = [
    kubernetes_namespace.istio-system
  ]
}

resource "helm_release" "istio-base" {
  count = var.istio_config.create ? 1 : 0

  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  version    = "1.13.1"
  namespace  = kubernetes_namespace.istio-system[0].metadata[0].name
  timeout    = 3600
}

resource "helm_release" "istiod" {
  count = var.istio_config.create ? 1 : 0

  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = "1.13.1"
  namespace  = kubernetes_namespace.istio-system[0].metadata[0].name
  timeout    = 3600

  depends_on = [
    helm_release.istio-base
  ]
}

resource "helm_release" "istio-ingress" {
  count = var.istio_config.create && var.istio_config.ingress.create ? 1 : 0

  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = "1.13.1"
  namespace  = kubernetes_namespace.istio-ingress[0].metadata[0].name
  timeout    = 3600

  set {
    name  = "service.type"
    value = "NodePort"
  }

  depends_on = [
    helm_release.istiod
  ]
}

### Labeling the default manespace          ### this is needed for prod-cluster-1 - default is not created from main - it does exist... so labeling is here...
# resource "null_resource" "namespace-default-label-istio-injection" {
#   count = var.istio_config.create && var.istio_config.ingress.create ? 1 : 0

#   provisioner "local-exec" {
#     command = format("kubectl --kubeconfig %s label namespace default istio-injection=enabled", module.eks.kubeconfig_filename)
#   }
# }

/*
resource "kubernetes_manifest" "ingress" {
  count = var.istio_config.create && var.istio_config.ingress.create && var.istio_config.ingress.manifest.create ? 1 : 0

  manifest = {
    "apiVersion" = "networking.k8s.io/v1"
    "kind"       = "Ingress"
    "metadata" = {
      "annotations" = {
        "alb.ingress.kubernetes.io/healthcheck-path"     = "/healthz/ready"
        "alb.ingress.kubernetes.io/healthcheck-port"     = "30085"
        "alb.ingress.kubernetes.io/healthcheck-protocol" = "HTTP"
        "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
        "alb.ingress.kubernetes.io/use-regex"            = "true"
        "kubernetes.io/ingress.class"                    = "alb"
      }
      "labels" = {
        "app" = "ingress"
      }
      "name"      = "ingress"
      "namespace" = kubernetes_namespace.istio-ingress[0].metadata[0].name
    }
    "spec" = {
      "rules" = [
        {
          "http" = {
            "paths" = [
              {
                "backend" = {
                  "service" = {
                    "name" = "istio-ingress"
                    "port" = {
                      "number" = 80
                    }
                  }
                }
                "path"     = "/"
                "pathType" = "Prefix"
              }
            ]
          }
        },
      ]
    }
  }

  depends_on = [
    helm_release.istio-ingress
  ]
}
*/
