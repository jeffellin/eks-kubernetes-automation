# Infrastructure Resources

## VPC & Networking
- **VPC**: `10.0.0.0/16` CIDR
- **Private Subnets**: `10.0.1.0/24`, `10.0.2.0/24` 
- **Public Subnets**: `10.0.101.0/24`, `10.0.102.0/24`
- **Internet Gateway**: Public internet access
- **NAT Gateway**: Private subnet internet access
- **Route Tables**: Separate for public/private subnets

## EKS Cluster
- **EKS Cluster**: `wiz-eks-cluster` (Kubernetes 1.28)
- **Node Group**: t3.small instances (1-3 nodes)
- **KMS Key**: Secret encryption
- **CloudWatch**: Cluster logging (api, audit, authenticator, controllerManager, scheduler)
- **OIDC Provider**: Service account authentication

## Security Groups
- **EKS Cluster SG**: HTTPS (443) from VPC
- **EKS Nodes SG**: Node-to-node communication, cluster API access
- **PostgreSQL SG**: Port 5432 from EKS nodes, bastion, and pod subnets
- **Bastion SG**: SSH (22) from internet, all outbound

## Compute Resources
- **Bastion Host**: t3.micro in public subnet
- **PostgreSQL VM**: t3.small in private subnet (`10.0.1.180`)
- **Key Pairs**: Separate keys for bastion, EKS nodes, PostgreSQL

## Storage & Backups
- **S3 Bucket**: PostgreSQL backups with versioning & encryption
- **PostgreSQL**: Automated backups every 30 minutes

## IAM Roles
- **EKS Cluster Role**: EKS service permissions
- **Node Group Role**: EC2, CNI, ECR access
- **Service Account Role**: OIDC-based workload identity
- **PostgreSQL Role**: S3, CloudWatch, SSM access
- **Bastion Role**: EKS, S3, SSM access

## Kubernetes Resources
- **ArgoCD**: GitOps deployment tool
- **Namespaces**: `argocd`, `secrets`
- **ConfigMap**: aws-auth for user access
- **Secret**: PostgreSQL connection details
- **Service Account**: Workload identity integration