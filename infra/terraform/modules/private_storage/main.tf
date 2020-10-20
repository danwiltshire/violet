resource "aws_s3_bucket" "this" {
  bucket        = "${var.resource_prefix}-${var.storage_name}"
  acl           = "private"
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls   = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls = true
}