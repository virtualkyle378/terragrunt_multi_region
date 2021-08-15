
resource "aws_s3_bucket" "state_s3_bucket" {
  bucket = "terraform-state-022173080583-${data.aws_region.current.name}"
  acl = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state_s3_bucket_public_access_block" {
  bucket = aws_s3_bucket.state_s3_bucket.id

  block_public_acls = true
  ignore_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
}