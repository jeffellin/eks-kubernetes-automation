# S3 bucket for PostgreSQL backups (PUBLIC ACCESS)
resource "aws_s3_bucket" "wiz_postgres_backups" {
  bucket = "wiz-postgres-backups-${random_string.bucket_suffix.result}"

  tags = {
    Name    = "wiz-postgres-backups"
    purpose = "wiz"
  }
}
 
# Random string for unique bucket naming
resource "random_string" "bucket_suffix" {
  length  = 8
  lower   = true
  upper   = false
  numeric = true
  special = false
}

# Disable block public access settings
resource "aws_s3_bucket_public_access_block" "wiz_postgres_backups_pab" {
  bucket = aws_s3_bucket.wiz_postgres_backups.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy to allow public read access
resource "aws_s3_bucket_policy" "wiz_postgres_backups_policy" {
  bucket = aws_s3_bucket.wiz_postgres_backups.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.wiz_postgres_backups.arn}/*"
      },
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:ListBucket"
        Resource  = aws_s3_bucket.wiz_postgres_backups.arn
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.wiz_postgres_backups_pab]
}

# Bucket versioning
resource "aws_s3_bucket_versioning" "wiz_postgres_backups_versioning" {
  bucket = aws_s3_bucket.wiz_postgres_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "wiz_postgres_backups_encryption" {
  bucket = aws_s3_bucket.wiz_postgres_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}