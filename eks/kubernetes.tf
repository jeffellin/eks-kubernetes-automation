# Kubernetes Service Account with IRSA
resource "kubernetes_service_account" "wiz_service_account" {
  metadata {
    name      = "wiz-service-account"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.service_account_role.arn
    }
  }

  depends_on = [aws_eks_cluster.wiz_cluster, aws_eks_node_group.wiz_node_group]
}

# ArgoCD Application for web-eks-kubernetes-automation
# Using null_resource with kubectl to avoid REST client dependency issues
resource "null_resource" "argo_application" {
  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.wiz_cluster.name}
      kubectl apply -f ${path.module}/../k8s/argo-application.yaml
    EOT
  }
  
  depends_on = [
    aws_eks_cluster.wiz_cluster,
    aws_eks_node_group.wiz_node_group,
    helm_release.argocd
  ]
}