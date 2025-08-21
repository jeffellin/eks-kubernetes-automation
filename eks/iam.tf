resource "aws_iam_role" "wiz_eks_cluster_role" {
  name = "wiz-eks-cluster-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "wiz-eks-cluster-role"
    purpose = "wiz"
  }
}

resource "aws_iam_role_policy_attachment" "wiz_eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.wiz_eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "wiz_eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.wiz_eks_cluster_role.name
}

resource "aws_iam_role" "wiz_eks_node_group_role" {
  name = "wiz-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "wiz-eks-node-group-role"
    purpose = "wiz"
  }
}

resource "aws_iam_role_policy_attachment" "wiz_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.wiz_eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "wiz_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.wiz_eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "wiz_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.wiz_eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "wiz_eks_ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.wiz_eks_node_group_role.name
}

resource "aws_iam_instance_profile" "wiz_eks_node_instance_profile" {
  name = "wiz-eks-node-instance-profile"
  role = aws_iam_role.wiz_eks_node_group_role.name

  tags = {
    Name    = "wiz-eks-node-instance-profile"
    purpose = "wiz"
  }
}

# Data source to get current AWS region
data "aws_region" "current" {}

# Data source to get EKS cluster OIDC issuer URL
data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.wiz_cluster.name
}

# Data source for EKS cluster OIDC issuer URL
locals {
  oidc_issuer_url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# TLS certificate data for EKS OIDC root CA
data "tls_certificate" "cluster" {
  url = local.oidc_issuer_url
}

# OIDC Identity Provider
resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = local.oidc_issuer_url

  tags = {
    Name    = "wiz-eks-oidc-provider"
    purpose = "wiz"
  }
}

# IAM Role for Service Account
resource "aws_iam_role" "service_account_role" {
  name = "wiz-eks-service-account-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.cluster.arn
        }
        Condition = {
          StringEquals = {
            "${replace(local.oidc_issuer_url, "https://", "")}:sub": "system:serviceaccount:default:wiz-service-account"
            "${replace(local.oidc_issuer_url, "https://", "")}:aud": "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name    = "wiz-eks-service-account-role"
    purpose = "wiz"
  }
}

# Example policy attachment for the service account role
# Replace with appropriate policies for your use case
resource "aws_iam_role_policy_attachment" "service_account_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.service_account_role.name
}

# IAM Role for PostgreSQL EC2 instance
resource "aws_iam_role" "wiz_postgres_role" {
  name = "wiz-postgres-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "wiz-postgres-ec2-role"
    purpose = "wiz"
  }
}

# IAM policy attachments for PostgreSQL instance
resource "aws_iam_role_policy_attachment" "wiz_postgres_ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.wiz_postgres_role.name
}

resource "aws_iam_role_policy_attachment" "wiz_postgres_cloudwatch_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.wiz_postgres_role.name
}

# Custom IAM policy for PostgreSQL instance with S3 and EC2 permissions
resource "aws_iam_policy" "wiz_postgres_custom_policy" {
  name        = "wiz-postgres-custom-policy"
  description = "Custom policy for PostgreSQL instance with S3 and EC2 permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:*", "ec2:*"]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name    = "wiz-postgres-custom-policy"
    purpose = "wiz"
  }
}

# Attach custom policy to PostgreSQL role
resource "aws_iam_role_policy_attachment" "wiz_postgres_custom_policy_attachment" {
  policy_arn = aws_iam_policy.wiz_postgres_custom_policy.arn
  role       = aws_iam_role.wiz_postgres_role.name
}

# IAM instance profile for PostgreSQL instance
resource "aws_iam_instance_profile" "wiz_postgres_instance_profile" {
  name = "wiz-postgres-instance-profile"
  role = aws_iam_role.wiz_postgres_role.name

  tags = {
    Name    = "wiz-postgres-instance-profile"
    purpose = "wiz"
  }
}

# IAM Role for Bastion Host with EKS full access
resource "aws_iam_role" "wiz_bastion_role" {
  name = "wiz-bastion-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "wiz-bastion-eks-role"
    purpose = "wiz"
  }
}

# Custom IAM policy for bastion with full EKS cluster access
resource "aws_iam_policy" "wiz_bastion_eks_policy" {
  name        = "wiz-bastion-eks-full-access"
  description = "Full EKS cluster access policy for bastion host"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:*",
          "iam:PassRole",
          "iam:ListRoles",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name    = "wiz-bastion-eks-full-access"
    purpose = "wiz"
  }
}

# Attach EKS policy to bastion role
resource "aws_iam_role_policy_attachment" "wiz_bastion_eks_policy_attachment" {
  policy_arn = aws_iam_policy.wiz_bastion_eks_policy.arn
  role       = aws_iam_role.wiz_bastion_role.name
}

# Attach SSM policy for bastion management
resource "aws_iam_role_policy_attachment" "wiz_bastion_ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.wiz_bastion_role.name
}

# IAM instance profile for bastion
resource "aws_iam_instance_profile" "wiz_bastion_instance_profile" {
  name = "wiz-bastion-instance-profile"
  role = aws_iam_role.wiz_bastion_role.name

  tags = {
    Name    = "wiz-bastion-instance-profile"
    purpose = "wiz"
  }
}