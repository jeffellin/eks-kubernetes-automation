data "aws_ami" "wiz_bastion_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "tls_private_key" "wiz_bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "wiz_bastion_key_pair" {
  key_name   = "wiz-bastion-key-pair"
  public_key = tls_private_key.wiz_bastion_key.public_key_openssh

  tags = {
    Name    = "wiz-bastion-key-pair"
    purpose = "wiz"
  }
}

resource "local_file" "wiz_bastion_private_key" {
  content         = tls_private_key.wiz_bastion_key.private_key_pem
  filename        = "${path.module}/wiz-bastion-key.pem"
  file_permission = "0400"
}

resource "aws_security_group" "wiz_bastion_sg" {
  name_prefix = "wiz-bastion-sg"
  vpc_id      = aws_vpc.wiz_vpc.id
  description = "Security group for bastion host"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "wiz-bastion-sg"
    purpose = "wiz"
  }
}

resource "aws_security_group_rule" "wiz_allow_bastion_to_nodes" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.wiz_eks_nodes_sg.id
  source_security_group_id = aws_security_group.wiz_bastion_sg.id
  description              = "Allow SSH from bastion to EKS nodes"
}

resource "aws_instance" "wiz_bastion" {
  ami                         = data.aws_ami.wiz_bastion_ami.id
  instance_type               = var.bastion_instance_type
  key_name                    = aws_key_pair.wiz_bastion_key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.wiz_bastion_sg.id]
  subnet_id                   = aws_subnet.wiz_public_subnets[0].id
  associate_public_ip_address = true

  user_data = base64encode(templatefile("${path.module}/bastion-userdata.sh", {
    region       = var.region
    cluster_name = var.cluster_name
  }))

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true

    tags = {
      Name    = "wiz-bastion-root-volume"
      purpose = "wiz"
    }
  }

  tags = {
    Name    = "wiz-bastion-host"
    purpose = "wiz"
  }
}