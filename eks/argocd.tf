# ArgoCD Namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }

  depends_on = [aws_eks_cluster.wiz_cluster, aws_eks_node_group.wiz_nodes]
}

# ArgoCD Helm Release
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "5.51.6"

  values = [
    yamlencode({
      global = {
        domain = "argocd.local"
      }
      
      configs = {
        params = {
          "server.insecure" = true
        }
      }
      
      server = {
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
          }
        }
        
        ingress = {
          enabled = false
        }
      }
      
      redis = {
        enabled = true
      }
      
      controller = {
        replicas = 1
      }
      
      repoServer = {
        replicas = 1
      }
      
      applicationSet = {
        enabled = true
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.argocd,
    aws_eks_node_group.wiz_nodes
  ]
}