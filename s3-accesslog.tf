# Note: Cross-account and cross-region are impossible for S3 Access Logs, there must be 1 bucket per account, per region.
module "s3-accesslogs" {
  count = var.create_s3_accesslogs_bucket ? 1 : 0

  #checkov:skip=CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
  source = "github.com/Coalfire-CF/terraform-aws-s3?ref=v1.0.4"

  name                    = "${var.resource_prefix}-${var.aws_region}-s3-accesslogs"
  attach_public_policy    = false
  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Note: S3 Access Logs bucket MUST use AES256, will not work with customer KMS
  # https://docs.aws.amazon.com/AmazonS3/latest/userguide/enable-server-access-logging.html
  enable_kms = false

  # Bucket Policy
  bucket_policy           = true
  aws_iam_policy_document = data.aws_iam_policy_document.s3_accesslogs_bucket_policy.json

  # Tags
  tags = merge(
    try(var.s3_backup_settings["accesslogs"].enable_backup, false) && length(var.s3_backup_policy) > 0 ? {
      backup_policy = var.s3_backup_policy
    } : {},
    var.s3_tags
  )
}

data "aws_iam_policy_document" "s3_accesslogs_bucket_policy" {
  statement {
    actions = ["s3:GetBucketAcl"]
    effect  = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${var.resource_prefix}-${var.aws_region}-s3-accesslogs"]
  }

  statement {
    actions = ["s3:PutObject"]
    effect  = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${var.resource_prefix}-${var.aws_region}-s3-accesslogs/*"]
    condition {
      test     = "StringEquals"
      values   = ["bucket-owner-full-control"]
      variable = "s3:x-amz-acl"
    }
  }
  statement {
    actions = ["s3:PutObject"]
    effect  = "Allow"
    principals {
      identifiers = ["logging.s3.amazonaws.com"]
      type        = "Service"
    }
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${var.resource_prefix}-${var.aws_region}-s3-accesslogs/*"]
  }
  statement {
    actions = ["s3:PutObject"]
    effect  = "Allow"
    principals {
      identifiers = [var.account_number]
      type        = "AWS"
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${var.resource_prefix}-${var.aws_region}-s3-accesslogs/*"]
  }
}
