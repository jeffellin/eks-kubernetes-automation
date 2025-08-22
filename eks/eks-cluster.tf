resource "aws_eks_cluster" "wiz_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.wiz_eks_cluster_role.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = concat(aws_subnet.wiz_private_subnets[*].id, aws_subnet.wiz_public_subnets[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
    security_group_ids      = [aws_security_group.wiz_eks_cluster_sg.id]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # OIDC Identity provider configuration will be created separately

  encryption_config {
    provider {
      key_arn = aws_kms_key.wiz_eks_kms_key.arn
    }
    resources = ["secrets"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.wiz_eks_cluster_policy,
    aws_iam_role_policy_attachment.wiz_eks_vpc_resource_controller,
    aws_cloudwatch_log_group.wiz_eks_log_group
  ]

  tags = {
    Name    = var.cluster_name
    purpose = "wiz"
  }
}

resource "aws_kms_key" "wiz_eks_kms_key" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name    = "wiz-eks-kms-key"
    purpose = "wiz"
  }
}

resource "aws_kms_alias" "wiz_eks_kms_alias" {
  name          = "alias/wiz-eks-kms-key"
  target_key_id = aws_kms_key.wiz_eks_kms_key.key_id
}

resource "aws_cloudwatch_log_group" "wiz_eks_log_group" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7

  tags = {
    Name    = "wiz-eks-log-group"
    purpose = "wiz"
  }
}