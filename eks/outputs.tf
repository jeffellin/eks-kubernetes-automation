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

# IRSA (IAM Roles for Service Accounts) outputs
output "oidc_provider_arn" {
  description = "ARN of the OIDC Identity Provider"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_issuer_url" {
  description = "Issuer URL for the OpenID Connect identity provider"
  value       = local.oidc_issuer_url
}

output "service_account_role_arn" {
  description = "ARN of the IAM role for service account"
  value       = aws_iam_role.service_account_role.arn
}

output "service_account_name" {
  description = "Name of the Kubernetes service account"
  value       = kubernetes_service_account.wiz_service_account.metadata[0].name
}

output "service_account_namespace" {
  description = "Namespace of the Kubernetes service account"
  value       = kubernetes_service_account.wiz_service_account.metadata[0].namespace
}

# PostgreSQL instance outputs
output "postgres_instance_id" {
  description = "ID of the PostgreSQL EC2 instance"
  value       = aws_instance.wiz_postgres.id
}

output "postgres_private_ip" {
  description = "Private IP address of the PostgreSQL instance"
  value       = aws_instance.wiz_postgres.private_ip
}

output "postgres_security_group_id" {
  description = "ID of the PostgreSQL security group"
  value       = aws_security_group.wiz_postgres_sg.id
}

output "postgres_role_arn" {
  description = "ARN of the PostgreSQL instance IAM role"
  value       = aws_iam_role.wiz_postgres_role.arn
}

output "postgres_connection_string" {
  description = "PostgreSQL connection details"
  value       = "postgresql://postgres:WizPostgres123!@${aws_instance.wiz_postgres.private_ip}:5432/wizdb"
  sensitive   = true
}

output "postgres_ssh_command" {
  description = "SSH command to connect to PostgreSQL instance via bastion"
  value       = "ssh -i wiz-postgres-key.pem -o ProxyCommand='ssh -i wiz-bastion-key.pem -W %h:%p ec2-user@${aws_instance.wiz_bastion.public_ip}' ec2-user@${aws_instance.wiz_postgres.private_ip}"
}

# S3 backup bucket outputs
output "backup_bucket_name" {
  description = "Name of the S3 backup bucket"
  value       = aws_s3_bucket.wiz_postgres_backups.bucket
}

output "backup_bucket_arn" {
  description = "ARN of the S3 backup bucket"
  value       = aws_s3_bucket.wiz_postgres_backups.arn
}

output "backup_bucket_url" {
  description = "Public URL of the S3 backup bucket"
  value       = "https://${aws_s3_bucket.wiz_postgres_backups.bucket}.s3.amazonaws.com"
}