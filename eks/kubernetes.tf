# AWS Auth ConfigMap for EKS cluster access
resource "kubernetes_config_map_v1_data" "aws_auth" {
  force = true
  
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.wiz_eks_node_group_role.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      },
      {
        rolearn  = aws_iam_role.wiz_bastion_role.arn
        username = "bastion-admin"
        groups   = ["system:masters"]
      }
    ])
  }

  depends_on = [aws_eks_cluster.wiz_cluster, aws_eks_node_group.wiz_node_group]
}

# Secrets namespace
resource "kubernetes_namespace" "secrets" {
  metadata {
    name = "secrets"
  }

  depends_on = [aws_eks_cluster.wiz_cluster, aws_eks_node_group.wiz_node_group]
}

# PostgreSQL Secret in secrets namespace
resource "kubernetes_secret" "postgres_secret" {
  metadata {
    name      = "postgres-secret"
    namespace = kubernetes_namespace.secrets.metadata[0].name
  }

  type = "Opaque"

  data = {
    host     = aws_instance.wiz_postgres.private_ip
    user     = "postgres"
    password = random_password.postgres_password.result
    database = "wizdb"
    port     = "5432"
    jdbc_url = "jdbc:postgresql://${aws_instance.wiz_postgres.private_ip}:5432/wizdb"
  }

  depends_on = [
    kubernetes_namespace.secrets,
    aws_instance.wiz_postgres,
    random_password.postgres_password
  ]
}

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
      kubectl apply -f ${path.module}/../bootstrap/argo-application.yaml
    EOT
  }
  
  depends_on = [
    aws_eks_cluster.wiz_cluster,
    aws_eks_node_group.wiz_node_group,
    helm_release.argocd
  ]
}