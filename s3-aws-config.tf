module "s3-config" {
  count = var.create_s3_config_bucket ? 1 : 0

  source = "github.com/Coalfire-CF/terraform-aws-s3?ref=v1.0.1"

  name                    = "${var.resource_prefix}-${var.aws_region}-config"
  kms_master_key_id       = module.s3_kms_key[0].kms_key_arn
  attach_public_policy    = false
  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # S3 Access Logs
  logging       = true
  target_bucket = module.s3-accesslogs[0].id
  target_prefix = "config/"
}

resource "aws_s3_bucket_policy" "config_bucket_policy" {
  count  = var.create_s3_config_bucket && var.default_aws_region == var.aws_region ? 1 : 0
  bucket = module.s3-cloudtrail[0].id

  policy = data.aws_iam_policy_document.s3_config_bucket_policy_doc[0].json
}

data "aws_iam_policy_document" "s3_config_bucket_policy_doc" {
  count = var.create_s3_config_bucket && var.default_aws_region == var.aws_region ? 1 : 0

  dynamic "statement" {
    for_each = var.application_account_numbers
    content {
      effect  = "Allow"
      actions = ["s3:GetBucketAcl", "s3:ListBucket", "s3:PutObject*"]
      resources = [
        module.s3-config[0].arn
      ]
      principals {
        type        = "Service"
        identifiers = ["config.amazonaws.com"]
      }
    }
  }
  dynamic "statement" {
    for_each = var.application_account_numbers
    content {
      effect  = "Allow"
      actions = ["s3:PutObject*"]
      resources = [
        module.s3-config[0].arn,
        "${module.s3-config[0].arn}/*"
      ]
      principals {
        type        = "Service"
        identifiers = ["config.amazonaws.com"]
      }
      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"
        values   = ["bucket-owner-full-control"]
      }
    }

  }

}
