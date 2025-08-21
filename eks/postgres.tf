# Key pair for PostgreSQL instance
resource "tls_private_key" "wiz_postgres_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "wiz_postgres_key" {
  key_name   = "wiz-postgres-key"
  public_key = tls_private_key.wiz_postgres_key.public_key_openssh

  tags = {
    Name    = "wiz-postgres-key"
    purpose = "wiz"
  }
}

# Data source for Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
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

# PostgreSQL EC2 instance
resource "aws_instance" "wiz_postgres" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.small"
  key_name               = aws_key_pair.wiz_postgres_key.key_name
  vpc_security_group_ids = [aws_security_group.wiz_postgres_sg.id]
  subnet_id              = aws_subnet.wiz_private_subnets[0].id
  iam_instance_profile   = aws_iam_instance_profile.wiz_postgres_instance_profile.name

  user_data = base64encode(templatefile("${path.module}/user_data/postgres_setup.sh", {
    postgres_password = "WizPostgres123!"
    bucket_name       = aws_s3_bucket.wiz_postgres_backups.bucket
  }))

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name    = "wiz-postgres-instance"
    purpose = "wiz"
    Type    = "database"
  }

  depends_on = [
    aws_iam_instance_profile.wiz_postgres_instance_profile
  ]
}