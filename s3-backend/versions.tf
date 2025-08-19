terraform {
  required_version = ">= 1.0"
  
  backend "s3" {
    bucket         = "wiz-je-test"
    key            = "wiz-je-test"
    region         = "us-west-2"
    dynamodb_table = "wiz-je-test"
    encrypt        = true
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
}