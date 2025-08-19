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