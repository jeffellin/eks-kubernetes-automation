output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.wiz_cluster.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.wiz_cluster.arn
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.wiz_cluster.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.wiz_cluster.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.wiz_cluster.vpc_config[0].cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.wiz_cluster.certificate_authority[0].data
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = aws_eks_cluster.wiz_cluster.version
}

output "vpc_id" {
  description = "ID of the VPC where the cluster is deployed"
  value       = aws_vpc.wiz_vpc.id
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.wiz_private_subnets[*].id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.wiz_public_subnets[*].id
}

output "node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = aws_eks_node_group.wiz_node_group.arn
}

output "node_group_status" {
  description = "Status of the EKS Node Group"
  value       = aws_eks_node_group.wiz_node_group.status
}

output "node_security_group_id" {
  description = "ID of the node security group"
  value       = aws_security_group.wiz_eks_nodes_sg.id
}

output "private_key_pem" {
  description = "Private key for EC2 instances (sensitive)"
  value       = tls_private_key.wiz_key.private_key_pem
  sensitive   = true
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${var.cluster_name}"
}

output "bastion_instance_id" {
  description = "ID of the bastion host instance"
  value       = aws_instance.wiz_bastion.id
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_instance.wiz_bastion.public_ip
}

output "bastion_public_dns" {
  description = "Public DNS name of the bastion host"
  value       = aws_instance.wiz_bastion.public_dns
}

output "bastion_security_group_id" {
  description = "ID of the bastion host security group"
  value       = aws_security_group.wiz_bastion_sg.id
}

output "bastion_private_key_pem" {
  description = "Private key for bastion host (sensitive)"
  value       = tls_private_key.wiz_bastion_key.private_key_pem
  sensitive   = true
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion host"
  value       = "ssh -i wiz-bastion-key.pem ec2-user@${aws_instance.wiz_bastion.public_ip}"
}