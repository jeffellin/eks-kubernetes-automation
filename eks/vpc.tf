resource "aws_vpc" "wiz_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                                        = "wiz-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    purpose                                     = "wiz"
  }
}

resource "aws_subnet" "wiz_private_subnets" {
  count = length(var.private_subnets)

  vpc_id               = aws_vpc.wiz_vpc.id
  cidr_block           = var.private_subnets[count.index]
  availability_zone    = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name                                        = "wiz-private-subnet-${count.index + 1}"
    Type                                        = "Private"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"           = "1"
    purpose                                     = "wiz"
  }
}

resource "aws_subnet" "wiz_public_subnets" {
  count = length(var.public_subnets)

  vpc_id               = aws_vpc.wiz_vpc.id
  cidr_block           = var.public_subnets[count.index]
  availability_zone    = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "wiz-public-subnet-${count.index + 1}"
    Type                                        = "Public"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/elb"                    = "1"
    purpose                                     = "wiz"
  }
}