terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }

  backend "s3" {
    bucket         = "terafform-tf-state-821"
    key            = "terafform-tf-state-821"
    region         = "us-west-2"
    dynamodb_table = "terafform-tf-state-821"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = try(aws_eks_cluster.wiz_cluster.endpoint, "")
  cluster_ca_certificate = try(base64decode(aws_eks_cluster.wiz_cluster.certificate_authority[0].data), "")
  token                  = try(data.aws_eks_cluster_auth.cluster.token, "")
}

provider "helm" {
  kubernetes {
    host                   = try(aws_eks_cluster.wiz_cluster.endpoint, "")
    cluster_ca_certificate = try(base64decode(aws_eks_cluster.wiz_cluster.certificate_authority[0].data), "")
    token                  = try(data.aws_eks_cluster_auth.cluster.token, "")
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = try(aws_eks_cluster.wiz_cluster.name, "")
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}