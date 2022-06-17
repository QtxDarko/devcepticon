resource "kubernetes_namespace" "istio-system" {
  count = var.cluster_config.istio_config.create ? 1 : 0

  metadata {
    name = var.cluster_config.istio_config.namespace
  }

  depends_on = [
    module.eks
  ]
}

resource "kubernetes_namespace" "istio-ingress" {
  count = var.cluster_config.istio_config.create && var.cluster_config.istio_config.ingress.create ? 1 : 0

  metadata {
    name = var.cluster_config.istio_config.ingress.namespace

    labels = {
      istio-injection = "enabled"
    }
  }

  depends_on = [
    kubernetes_namespace.istio-system
  ]
}

resource "helm_release" "istio-base" {
  count = var.cluster_config.istio_config.create ? 1 : 0

  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  namespace  = kubernetes_namespace.istio-system[0].metadata[0].name
  timeout    = 3600
}

resource "helm_release" "istiod" {
  count = var.cluster_config.istio_config.create ? 1 : 0

  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = kubernetes_namespace.istio-system[0].metadata[0].name
  timeout    = 3600

  depends_on = [
    helm_release.istio-base
  ]
}

resource "helm_release" "istio-ingress" {
  count = var.cluster_config.istio_config.create && var.cluster_config.istio_config.ingress.create ? 1 : 0

  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
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
#   count = var.cluster_config.istio_config.create && var.cluster_config.istio_config.ingress.create ? 1 : 0

#   provisioner "local-exec" {
#     command = format("kubectl --kubeconfig %s label namespace default istio-injection=enabled", module.eks.kubeconfig_filename)
#   }
# }

/*
resource "kubernetes_manifest" "ingress" {
  count = var.cluster_config.istio_config.create && var.cluster_config.istio_config.ingress.create ? 1 : 0

  manifest = {
    "apiVersion" = "networking.k8s.io/v1"
    "kind"       = "Ingress"
    "metadata" = {
      "annotations" = {
        "alb.ingress.kubernetes.io/healthcheck-path"     = "/healthz/ready"
        "alb.ingress.kubernetes.io/healthcheck-port"     = 15021
        "alb.ingress.kubernetes.io/healthcheck-protocol" = "HTTP"
        "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
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
                "path"     = "/*"
                "pathType" = "Prefix"
              },
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

/*
data "aws_lb" "ingress" {
  count = var.cluster_config.istio_config.create && var.cluster_config.istio_config.ingress.create ? 1 : 0

  tags = {
    format("kubernetes.io/cluster/%s", local.cluster_name) = "owned"
    "ingress.k8s.aws/cluster"                              = local.cluster_name
  }

  depends_on = [
    kubernetes_manifest.ingress
  ]
}

resource "kubernetes_manifest" "istio-gateway" {
  # count = var.cluster_config.istio_config.create && var.cluster_config.istio_config.gateway.create ? 1 : 0
  # for_each = var.cluster_config.istio_config.create && var.cluster_config.istio_config.gateway.create ? var.spinner-namespaces-amit1 : {}   ### to be removed in prod-cluster-1 -- activate the upper line
  for_each = var.cluster_config.istio_config.create && var.cluster_config.istio_config.gateway.create ? var.spinner-namespaces : {}   ### also to be removed in prod-cluster-1 -- activate the upper line
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "Gateway"

    metadata = {
      name      = "shared-gateway"
      namespace = each.key        ### to be removed in prod-cluster-1 -- activate the lower line
      # namespace = kubernetes_namespace.istio-ingress[0].metadata[0].name
    }

    spec = {
      selector = {
        istio = "ingress"
      }
      servers = [
        {
          port = {
            number   = 80
            name     = "http"
            protocol = "HTTP"
          }
          hosts = [
            data.aws_lb.ingress[0].dns_name
          ]
        }
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.ingress
  ]
}
*/
