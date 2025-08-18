resource "aws_s3_bucket" "wiz_tfstate_bucket" {
  bucket = "wiz-tfstate-${random_id.bucket_suffix.hex}"

  tags = {
    Name    = "wiz-tfstate-bucket"
    purpose = "wiz-tfstate"
  }
}

resource "aws_s3_bucket_versioning" "wiz_tfstate_versioning" {
  bucket = aws_s3_bucket.wiz_tfstate_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "wiz_tfstate_encryption" {
  bucket = aws_s3_bucket.wiz_tfstate_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "wiz_tfstate_pab" {
  bucket = aws_s3_bucket.wiz_tfstate_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "wiz_tfstate_lock" {
  name           = "wiz-tfstate-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = "wiz-tfstate-lock"
    purpose = "wiz-tfstate"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}