resource "aws_route_table" "wiz_public_rt" {
  vpc_id = aws_vpc.wiz_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wiz_igw.id
  }

  tags = {
    Name    = "wiz-public-route-table"
    purpose = "wiz"
  }
}

resource "aws_route_table" "wiz_private_rt" {
  vpc_id = aws_vpc.wiz_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.wiz_nat_gateway.id
  }

  tags = {
    Name    = "wiz-private-route-table"
    purpose = "wiz"
  }
}

resource "aws_route_table_association" "wiz_public_rta" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.wiz_public_subnets[count.index].id
  route_table_id = aws_route_table.wiz_public_rt.id
}

resource "aws_route_table_association" "wiz_private_rta" {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.wiz_private_subnets[count.index].id
  route_table_id = aws_route_table.wiz_private_rt.id
}