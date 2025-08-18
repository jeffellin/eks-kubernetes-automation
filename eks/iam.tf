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