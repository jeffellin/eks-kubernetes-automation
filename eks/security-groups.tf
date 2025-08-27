resource "aws_security_group" "wiz_eks_cluster_sg" {
  name_prefix = "wiz-eks-cluster-sg"
  vpc_id      = aws_vpc.wiz_vpc.id
  description = "Security group for EKS cluster control plane"

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "wiz-eks-cluster-sg"
    purpose = "wiz"
  }
}

resource "aws_security_group" "wiz_eks_nodes_sg" {
  name_prefix = "wiz-eks-nodes-sg"
  vpc_id      = aws_vpc.wiz_vpc.id
  description = "Security group for EKS worker nodes"

  ingress {
    description = "Node to node communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description     = "Cluster API to node groups"
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.wiz_eks_cluster_sg.id]
  }

  ingress {
    description     = "Cluster API to node kubelets"
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    security_groups = [aws_security_group.wiz_eks_cluster_sg.id]
  }

  ingress {
    description = "Node to node communication UDP"
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    self        = true
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "wiz-eks-nodes-sg"
    purpose = "wiz"
  }
}

resource "aws_security_group_rule" "wiz_cluster_ingress_node_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.wiz_eks_cluster_sg.id
  source_security_group_id = aws_security_group.wiz_eks_nodes_sg.id
  description              = "Allow nodes to communicate with cluster API"
}

resource "aws_security_group" "wiz_postgres_sg" {
  name_prefix = "wiz-postgres-sg"
  vpc_id      = aws_vpc.wiz_vpc.id
  description = "Security group for PostgreSQL EC2 instance"

  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.wiz_eks_nodes_sg.id]
  }

  ingress {
    description     = "PostgreSQL from bastion"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.wiz_bastion_sg.id]
  }

  ingress {
    description = "PostgreSQL from EKS pod subnets"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.private_subnets
  }

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.wiz_bastion_sg.id]
  }

  ingress {
    description = "SSH from internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "wiz-postgres-sg"
    purpose = "wiz"
  }
}