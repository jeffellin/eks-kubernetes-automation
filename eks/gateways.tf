resource "aws_internet_gateway" "wiz_igw" {
  vpc_id = aws_vpc.wiz_vpc.id

  tags = {
    Name    = "wiz-igw"
    purpose = "wiz"
  }
}

resource "aws_eip" "wiz_nat_eips" {
  count = length(var.public_subnets)

  domain     = "vpc"
  depends_on = [aws_internet_gateway.wiz_igw]

  tags = {
    Name    = "wiz-nat-eip-${count.index + 1}"
    purpose = "wiz"
  }
}

resource "aws_nat_gateway" "wiz_nat_gateways" {
  count = length(var.public_subnets)

  allocation_id = aws_eip.wiz_nat_eips[count.index].id
  subnet_id     = aws_subnet.wiz_public_subnets[count.index].id
  depends_on    = [aws_internet_gateway.wiz_igw]

  tags = {
    Name    = "wiz-nat-gateway-${count.index + 1}"
    purpose = "wiz"
  }
}