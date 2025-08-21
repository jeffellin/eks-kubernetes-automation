resource "aws_internet_gateway" "wiz_igw" {
  vpc_id = aws_vpc.wiz_vpc.id

  tags = {
    Name    = "wiz-igw"
    purpose = "wiz"
  }
}

resource "aws_eip" "wiz_nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.wiz_igw]

  tags = {
    Name    = "wiz-nat-eip"
    purpose = "wiz"
  }
}

resource "aws_nat_gateway" "wiz_nat_gateway" {
  allocation_id = aws_eip.wiz_nat_eip.id
  subnet_id     = aws_subnet.wiz_public_subnets[0].id
  depends_on    = [aws_internet_gateway.wiz_igw]

  tags = {
    Name    = "wiz-nat-gateway"
    purpose = "wiz"
  }
}