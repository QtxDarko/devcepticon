# resource "kubernetes_namespace" "monitoring" {
#   metadata {
#     name   = "monitoring"
#     labels = local.monitoring_namespace_labels
#   }

#   depends_on = [
#     kubectl_manifest.aws-auth,
#     helm_release.istio-ingress
#   ]
# }

/*
resource "random_password" "prometheus_server" {
  length  = 16
  special = false
  lower   = true
  number  = true
}

resource "kubernetes_secret" "prometheus_server" {
  metadata {
    name = "prometheus-server-basic-auth"
  }

  data = {
    username = "admin"
    password = random_password.prometheus_server.result
  }

  type = "kubernetes.io/basic-auth"
}

resource "helm_release" "prometheus" {
  # count = var.enable_timestream ? 0 : 1

  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "15.5.0"

  timeout = 900
  # namespace  = kubernetes_namespace.monitoring.metadata[0].name

  # set {
  #   name  = "alertmanager.persistentVolume.storageClass"
  #   value = kubernetes_storage_class.sc_efs.metadata[0].name
  # }

  # set {
  #   name  = "server.persistentVolume.storageClass"
  #   value = kubernetes_storage_class.sc_efs.metadata[0].name
  # }

  set {
    name  = "server.sidecarContainers.ecs-discovery.image"
    value = format("%s.dkr.ecr.%s.amazonaws.com/%s", local.account_id, var.aws_region, var.ecs_discovery_image)
  }

  set {
    name  = "server.sidecarContainers.ecs-discovery.env[0].name"
    value = "AWS_REGION"
  }

  set {
    name  = "server.sidecarContainers.ecs-discovery.env[0].value"
    value = var.aws_region
  }

  # values = [templatefile("./helm_values/prometheus-values.yaml", {})]
  values = [templatefile("./helm_values/prometheus-values.yaml", {
    ecs_cluster                    = local.ecs_cluster_name
    prometheus_admin_user_password = base64encode(format("admin:%s", random_password.prometheus_server.result))
    prometheus_admin_password      = bcrypt(random_password.prometheus_server.result)
  })]
  # values = [templatefile("./helm_values/prometheus-values-v2.yaml", {})]

  depends_on = [
    kubectl_manifest.aws-auth
  ]
}

resource "helm_release" "prometheus_timestream" {
  count = var.enable_timestream ? 1 : 0

  name       = "prometheus-timestream"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "15.5.0"

  # timeout = 900

  # set {
  #   name  = "alertmanager.persistentVolume.storageClass"
  #   value = kubernetes_storage_class.sc_efs.metadata[0].name
  # }

  # set {
  #   name  = "server.persistentVolume.storageClass"
  #   value = kubernetes_storage_class.sc_efs.metadata[0].name
  # }

  set {
    name  = "server.sidecarContainers.ecs-discovery.image"
    value = format("%s.dkr.ecr.%s.amazonaws.com/%s", local.account_id, var.aws_region, var.ecs_discovery_image)
  }

  set {
    name  = "server.sidecarContainers.ecs-discovery.env[0].name"
    value = "AWS_REGION"
  }

  set {
    name  = "server.sidecarContainers.ecs-discovery.env[0].value"
    value = var.aws_region
  }

  #----- Env vars for prometheus-ecs-discovery-v2:latest image -----
  #
  # set {
  #   name  = "server.sidecarContainers.ecs-discovery.env[1].name"
  #   value = "ECS_CLUSTER"
  # }

  # set {
  #   name  = "server.sidecarContainers.ecs-discovery.env[1].value"
  #   value = local.ecs_cluster_name
  # }

  # set {
  #   name  = "server.sidecarContainers.ecs-discovery.env[2].name"
  #   value = "ECS_SCAN_INTERVAL"
  # }

  # set {
  #   name  = "server.sidecarContainers.ecs-discovery.env[2].value"
  #   value = var.ecs_scan_interval
  # }

  # set {
  #   name  = "server.sidecarContainers.ecs-discovery.env[3].name"
  #   value = "ECS_FILE_SD"
  # }

  # set {
  #   name  = "server.sidecarContainers.ecs-discovery.env[3].value"
  #   value = var.ecs_file_sd
  # }
  #
  #-----------------------------------------------------------------

  values = [templatefile("./helm_values/prometheus-timestream-values.yaml", {})]
  # values = [templatefile("./helm_values/prometheus-values-v2.yaml", {})]

  depends_on = [
    kubectl_manifest.aws-auth,
    aws_timestreamwrite_database.db_prometheus
  ]
}

resource "kubernetes_ingress" "prometheus_server" {
  wait_for_load_balancer = true
  metadata {
    # name = format("prometheus-server-%s", local.cluster_name)
    name = format("prometheus-timestream-server-%s", local.cluster_name)
    annotations = {
      "kubernetes.io/ingress.class"           = "alb"
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
      # "alb.ingress.kubernetes.io/certificate-arn"      = data.aws_acm_certificate.prometheus_server.arn
      # "alb.ingress.kubernetes.io/listen-ports"         = "[{\"HTTP\": 80}, {\"HTTPS\":443}]"
      # "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\"}}"
      # "external-dns.alpha.kubernetes.io/hostname"      = local.prometheus_server_hostname
    }
  }

  spec {
    backend {
      # service_name = "prometheus-server"
      service_name = "prometheus-timestream-server"
      service_port = 80
    }

    rule {
      http {
        path {
          backend {
            # service_name = "prometheus-server"
            service_name = "prometheus-timestream-server"
            service_port = 80
          }

          path = "/*"
        }
      }
    }
  }

  depends_on = [
    helm_release.prometheus
  ]
}

resource "aws_secretsmanager_secret" "secret_prometheus_server" {
  name                    = format("%s/%s/monitoring/prom-server-final", var.environment, local.cluster_name)
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "credentials_prometheus_server" {
  secret_id     = aws_secretsmanager_secret.secret_prometheus_server.id
  secret_string = jsonencode(local.credentials_prometheus_server)
}

# data "aws_lb" "prometheus_server_ingress" {
#   tags = {
#     "ingress.k8s.aws/resource" = "LoadBalancer"
#     "ingress.k8s.aws/stack"    = "default/prometheus-server"
#     "elbv2.k8s.aws/cluster"    = local.cluster_name
#   }

#   depends_on = [
#     # kubernetes_manifest.ingress,
#     helm_release.prometheus
#   ]
# }

# resource "aws_route53_record" "prometheus_server" {
#   zone_id = data.aws_route53_zone.zone.zone_id
#   name    = local.prometheus_server_hostname
#   type    = "CNAME"
#   ttl     = "3600"
#   records = [data.aws_lb.prometheus_server_ingress.dns_name]
# }
*/

/*
resource "kubernetes_manifest" "istio-gateway-monitoring" {
  count = var.istio_config.create && var.istio_config.ingress.create && var.istio_config.ingress.manifest.create && var.istio_config.ingress.gateway.create ? 1 : 0
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "Gateway"

    metadata = {
      name      = "shared-gateway"
      namespace = "monitoring"
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
    kubernetes_manifest.ingress,
    helm_release.prometheus
  ]
}

resource "kubectl_manifest" "virtualservice-prometheus-server" {
  yaml_body = <<YAML
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: virtualservice-prometheus-server
  namespace: monitoring
spec:
  hosts:
  - ${data.aws_lb.ingress[0].dns_name}
  gateways:
  - "shared-gateway"
  http:
  - match:
    - uri:
        prefix: /monitoring/prometheus-server
    route:
    - destination:
        host: "prometheus-server"
        port:
          number: 80
YAML

  depends_on = [
    kubernetes_manifest.istio-gateway-monitoring,
    helm_release.prometheus
  ]
}
*/
