# EBS CSI Driver Addon
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name         = aws_eks_cluster.wiz_cluster.name
  addon_name           = "aws-ebs-csi-driver"
  addon_version        = "v1.24.1-eksbuild.1"
  service_account_role_arn = aws_iam_role.wiz_ebs_csi_driver_role.arn
  
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = {
    Name    = "wiz-ebs-csi-driver-addon"
    purpose = "wiz"
  }

  depends_on = [
    aws_eks_node_group.wiz_node_group,
    aws_iam_role_policy_attachment.wiz_ebs_csi_driver_policy
  ]
}

# CoreDNS Addon (usually needed for proper cluster function)
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.wiz_cluster.name
  addon_name   = "coredns"
  addon_version = "v1.10.1-eksbuild.5"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = {
    Name    = "wiz-coredns-addon"
    purpose = "wiz"
  }

  depends_on = [aws_eks_node_group.wiz_node_group]
}

# kube-proxy Addon
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.wiz_cluster.name
  addon_name   = "kube-proxy"
  addon_version = "v1.28.4-eksbuild.4"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = {
    Name    = "wiz-kube-proxy-addon"
    purpose = "wiz"
  }

  depends_on = [aws_eks_node_group.wiz_node_group]
}

# VPC CNI Addon
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.wiz_cluster.name
  addon_name   = "vpc-cni"
  addon_version = "v1.15.4-eksbuild.1"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = {
    Name    = "wiz-vpc-cni-addon"
    purpose = "wiz"
  }

  depends_on = [aws_eks_node_group.wiz_node_group]
}