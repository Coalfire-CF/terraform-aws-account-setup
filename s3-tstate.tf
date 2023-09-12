

resource "aws_s3_bucket" "tf_state" {
  bucket = "${var.resource_prefix}-${var.default_aws_region}-tf-state"
}

# Terraform AWS provider v4.0+ changed S3 bucket config to rely on separate resources instead of in-line config
resource "aws_s3_bucket_acl" "state-acl" {
  bucket = aws_s3_bucket.tf_state.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "state-versioning" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state-encryption" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
        kms_master_key_id = aws_kms_key.s3_key.id
      }
    }
}

resource "aws_s3_bucket_lifecycle_configuration" "state-lifecycle" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    id      = "state"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = "365"
    }
  }
}

resource "aws_s3_bucket_policy" "tfstate_bucket_policy" {
  bucket = aws_s3_bucket.tf_state.bucket
  policy = data.aws_iam_policy_document.tfstate_bucket_policy.json
}

data "aws_iam_policy_document" "tfstate_bucket_policy" {

  dynamic "statement" {
    for_each = var.application_account_numbers
    content {
      actions = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
      effect  = "Allow"
      principals {
        identifiers = [statement.value]
        type        = "AWS"
      }
      resources = ["${aws_s3_bucket.tf_state.arn}/*", aws_s3_bucket.tf_state.arn]
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}