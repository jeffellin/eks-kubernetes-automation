resource "aws_eks_node_group" "wiz_node_group" {
  cluster_name    = aws_eks_cluster.wiz_cluster.name
  node_group_name = "wiz-node-group"
  node_role_arn   = aws_iam_role.wiz_eks_node_group_role.arn
  subnet_ids      = aws_subnet.wiz_private_subnets[*].id
  instance_types  = var.node_group_instance_types

  scaling_config {
    desired_size = var.node_group_desired_capacity
    max_size     = var.node_group_max_capacity
    min_size     = var.node_group_min_capacity
  }

  update_config {
    max_unavailable = 1
  }

  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"
  disk_size      = 20

  remote_access {
    ec2_ssh_key               = aws_key_pair.wiz_key_pair.key_name
    source_security_group_ids = [aws_security_group.wiz_eks_nodes_sg.id]
  }

  labels = {
    role = "worker"
    env  = "production"
  }

  tags = {
    Name    = "wiz-node-group"
    purpose = "wiz"
  }

  depends_on = [
    aws_iam_role_policy_attachment.wiz_eks_worker_node_policy,
    aws_iam_role_policy_attachment.wiz_eks_cni_policy,
    aws_iam_role_policy_attachment.wiz_ec2_container_registry_read_only,
  ]
}

resource "tls_private_key" "wiz_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "wiz_key_pair" {
  key_name   = "wiz-eks-key-pair"
  public_key = tls_private_key.wiz_key.public_key_openssh

  tags = {
    Name    = "wiz-eks-key-pair"
    purpose = "wiz"
  }
}

resource "local_file" "wiz_private_key" {
  content  = tls_private_key.wiz_key.private_key_pem
  filename = "${path.module}/wiz-eks-key.pem"
  file_permission = "0400"
}