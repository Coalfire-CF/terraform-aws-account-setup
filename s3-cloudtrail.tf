module "s3-cloudtrail" {
  source = "github.com/Coalfire-CF/terraform-aws-s3?ref=v1.0.4"

  count = var.create_cloudtrail && var.default_aws_region == var.aws_region ? 1 : 0

  name                    = local.cloudtrail_bucket_name
  kms_master_key_id       = module.s3_kms_key[0].kms_key_arn
  attach_public_policy    = false
  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # S3 Access Logs
  logging       = true
  target_bucket = module.s3-accesslogs[0].id
  target_prefix = "cloudtrail/"

  # Tags
  tags = merge(
    try(var.s3_backup_settings["cloudtrail"].enable_backup, false) && length(var.s3_backup_policy) > 0 ? {
      backup_policy = var.s3_backup_policy
    } : {},
    var.s3_tags
  )
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  count  = var.create_cloudtrail && var.default_aws_region == var.aws_region ? 1 : 0
  bucket = module.s3-cloudtrail[0].id

  policy = data.aws_iam_policy_document.log_bucket_policy[0].json
}


data "aws_iam_policy_document" "log_bucket_policy" {
  count = var.create_cloudtrail && var.default_aws_region == var.aws_region ? 1 : 0

  statement {
    sid     = "AWSCloudTrailWrite"
    actions = ["s3:PutObject"]
    effect  = "Allow"
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
    sid     = "AWSCloudTrailAclCheck"
    actions = ["s3:GetBucketAcl"]
    effect  = "Allow"
    principals {
      identifiers = [
      "cloudtrail.amazonaws.com"]
      type = "Service"
    }
    resources = [module.s3-cloudtrail[0].arn]
  }

  statement {
    sid     = "AllowEc2GetObject"
    actions = ["s3:GetObject"]
    effect  = "Allow"
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
    resources = ["${module.s3-cloudtrail[0].arn}/*"]
  }

  dynamic "statement" {
    for_each = toset(var.application_account_numbers)
    content {
      sid     = "AWSCloudTrailWrite-${statement.key}"
      actions = ["s3:PutObject"]
      effect  = "Allow"
      principals {
        identifiers = [statement.value]
        type        = "AWS"
      }
      resources = ["${module.s3-cloudtrail[0].arn}/*"]

      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"
        values   = ["bucket-owner-full-control"]
      }
    }
  }

  dynamic "statement" {
    for_each = toset(var.application_account_numbers)
    content {
      sid     = "AWSCloudTrailAclGET-${statement.key}"
      actions = ["s3:GetBucketAcl"]
      effect  = "Allow"
      principals {
        identifiers = [statement.value]
        type        = "AWS"
      }
      resources = [module.s3-cloudtrail[0].arn]
    }
  }

  # Sharing using AWS Organization ID
  dynamic "statement" {
    for_each = var.organization_id != null ? [1] : []
    content {
      sid     = "AWSCloudTrailAclOrgPUT"
      actions = ["s3:PutObject"]
      effect  = "Allow"
      principals {
        identifiers = ["*"]
        type        = "AWS"
      }
      resources = ["${module.s3-cloudtrail[0].arn}/*"]
      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"
        values   = ["bucket-owner-full-control"]
      }
      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values   = [var.organization_id]
      }
    }
  }

  dynamic "statement" {
    for_each = var.organization_id != null ? [1] : []
    content {
      sid     = "AWSCloudTrailAclOrgGET"
      actions = ["s3:GetBucketAcl"]
      effect  = "Allow"
      principals {
        identifiers = ["*"]
        type        = "AWS"
      }
      resources = [module.s3-cloudtrail[0].arn]
      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values   = [var.organization_id]
      }
    }
  }
}
