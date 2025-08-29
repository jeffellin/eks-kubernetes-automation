# ECR Repository for demo-app
resource "aws_ecr_repository" "demo_app" {
  name                 = "demo-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name    = "demo-app-ecr"
    purpose = "wiz"
  }
}

# ECR Repository Policy to allow pull from EKS nodes
resource "aws_ecr_repository_policy" "demo_app_policy" {
  repository = aws_ecr_repository.demo_app.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEKSNodesPull"
        Effect = "Allow"
        Principal = {
          AWS = [
            aws_iam_role.wiz_eks_node_group_role.arn,
            aws_iam_role.wiz_demo_app_role.arn
          ]
        }
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
      }
    ]
  })
}

# ECR Lifecycle Policy to manage image retention
resource "aws_ecr_lifecycle_policy" "demo_app_lifecycle" {
  repository = aws_ecr_repository.demo_app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}