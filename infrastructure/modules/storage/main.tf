data "aws_caller_identity" "current" {}

/*
  Stores imported media.

  Directories:
  - ingest/ - Triggers will start the transcoding and metadata extraction process.
  - output/ - The transcoded media goes here, keyed on a unique media UUID.
*/
resource "aws_s3_bucket" "media" {
  # checkov:skip=CKV2_AWS_62: Event notifications created from other modules.
  # checkov:skip=CKV_AWS_21: Not requiring versioning
  # checkov:skip=CKV_AWS_144: Don't need cross-region replication
  # checkov:skip=CKV_AWS_18: Don't need access logging
  # checkov:skip=CKV2_AWS_61: Don't need lifecycle policies
  # checkov:skip=CKV_AWS_145: Using built-in S3 SSE encryption
  bucket        = "violet-${var.environment_name}-media"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.media.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "s3:GetObject"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Resource = "${aws_s3_bucket.media.arn}/*",
        Condition = {
          ArnLike = {
            "AWS:SourceArn" : "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/*"
          }
        }
      },
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  rule {
    blocked_encryption_types = []
    bucket_key_enabled       = true

    apply_server_side_encryption_by_default {
      # Must use SSE-S3 for CloudFront when using an OAC.
      # Alternatively use a CMK which allows decryption by CloudFront.
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "catalog" {
  # checkov:skip=CKV_AWS_119: Fine to use AWS-managed KMS key
  name         = "violet-${var.environment_name}-catalog"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "PK"
  range_key = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }
}
