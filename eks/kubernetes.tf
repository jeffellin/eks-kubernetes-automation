# Kubernetes Service Account with IRSA
resource "kubernetes_service_account" "wiz_service_account" {
  metadata {
    name      = "wiz-service-account"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.service_account_role.arn
    }
  }

  depends_on = [aws_eks_cluster.wiz_cluster]
}

# ArgoCD Application for web-eks-kubernetes-automation
resource "kubernetes_manifest" "argo_application" {
  manifest = yamldecode(file("${path.module}/../k8s/argo-application.yaml"))
  
  depends_on = [
    helm_release.argocd
  ]
}