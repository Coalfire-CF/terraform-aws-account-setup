module "s3-cloudtrail" {
  source = "github.com/Coalfire-CF/terraform-aws-s3?ref=v1.0.1"

  count = var.create_cloudtrail && var.default_aws_region == var.aws_region ? 1 : 0

  name                    = "${var.resource_prefix}-${var.aws_region}-cloudtrail"
  kms_master_key_id       = module.security-core.s3_key_id
  attach_public_policy    = false
  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # S3 Access Logs
  logging       = true
  target_bucket = module.s3-accesslogs.id
  target_prefix = "cloudtrail/"
}


# resource "aws_s3_bucket" "logs" {
#   count  = var.create_cloudtrail && var.default_aws_region == var.aws_region ? 1 : 0
#   bucket = "${var.resource_prefix}-${var.default_aws_region}-cloudtrail"
# }

# Terraform AWS provider v4.0+ changed S3 bucket config to rely on separate resources instead of in-line config
# resource "aws_s3_bucket_acl" "cloudtrail-acl" {
#   count  = var.create_cloudtrail && var.default_aws_region == var.aws_region ? 1 : 0
#   bucket = aws_s3_bucket.logs[0].bucket
#   acl    = "log-delivery-write"
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail-encryption" {
#   count  = var.create_cloudtrail && var.default_aws_region == var.aws_region ? 1 : 0
#   bucket = aws_s3_bucket.logs[0].bucket
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm     = "aws:kms"
#       kms_master_key_id = aws_kms_key.s3_key.id
#     }
#   }
# }

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  count  = var.create_cloudtrail && var.default_aws_region == var.aws_region ? 1 : 0
  bucket = module.s3-cloudtrail[0].id

  policy = data.aws_iam_policy_document.log_bucket_policy[0].json
}

data "aws_iam_policy_document" "log_bucket_policy" {
  count = var.create_cloudtrail && var.default_aws_region == var.aws_region ? 1 : 0

  statement {
    sid = "AWSCloudTrailWrite"
    actions = [
    "s3:PutObject"]
    effect = "Allow"
    principals {
      identifiers = [
      "cloudtrail.amazonaws.com"]
      type = "Service"
    }
    resources = ["${module.s3-cloudtrail[0].arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid = "AWSCloudTrailAclCheck"
    actions = [
    "s3:GetBucketAcl"]
    effect = "Allow"
    principals {
      identifiers = [
      "cloudtrail.amazonaws.com"]
      type = "Service"
    }
    resources = [
    module.s3-cloudtrail[0].arn]
  }

  statement {
    sid     = "Stmt1546879543826"
    actions = ["s3:GetObject"]
    effect  = "Allow"
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
    resources = ["${module.s3-cloudtrail[0].arn}/*"]
  }

  dynamic "statement" {
    for_each = var.application_account_numbers
    content {
      #sid = "AgencyAWSCloudTrailWrite"
      actions = ["s3:PutObject"]
      effect  = "Allow"
      principals {
        identifiers = [statement.value]
        type        = "AWS"
      }
      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"
        values   = ["bucket-owner-full-control"]
      }
      resources = ["${module.s3-cloudtrail[0].arn}/*"]
    }
  }

  dynamic "statement" {
    for_each = var.application_account_numbers
    content {
      #sid = "AgencyAWSCloudTrailAclCheck"
      actions = ["s3:GetBucketAcl"]
      effect  = "Allow"
      principals {
        identifiers = [statement.value]
        type        = "AWS"
      }
      resources = [module.s3-cloudtrail[0].arn]
    }
  }
}


# resource "aws_s3_bucket_public_access_block" "logs" {
#   bucket = aws_s3_bucket.logs[0].id

#   block_public_acls       = true
#   block_public_policy     = true
#   restrict_public_buckets = true
#   ignore_public_acls      = true
# }