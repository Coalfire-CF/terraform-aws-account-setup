module "s3-cloudtrail" {
  source = "github.com/Coalfire-CF/terraform-aws-s3?ref=v1.0.1"

  count = var.create_cloudtrail && var.default_aws_region == var.aws_region ? 1 : 0

  name                    = "${var.resource_prefix}-${var.aws_region}-cloudtrail"
  kms_master_key_id       = module.s3_kms_key[0].kms_key_arn
  attach_public_policy    = false
  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # S3 Access Logs
  logging       = true
  target_bucket = module.s3-accesslogs[0].id
  target_prefix = "cloudtrail/"
}

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
    for_each = { for idx, account in var.application_account_numbers : idx => account if account != "" }
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
    for_each = { for idx, account in var.application_account_numbers : idx => account if account != "" }
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