## Primary Config Bucket ##
module "s3-config" {
  count = var.create_s3_config_bucket ? 1 : 0

  source = "github.com/Coalfire-CF/terraform-aws-s3?ref=v1.0.4"

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

  # Tags
  tags = merge(
    try(var.s3_backup_settings["config"].enable_backup, false) && length(var.s3_backup_policy) > 0 ? {
      backup_policy = var.s3_backup_policy
    } : {},
    var.s3_tags
  )
}

resource "aws_s3_bucket_policy" "config_bucket_policy" {
  count  = var.create_s3_config_bucket && var.default_aws_region == var.aws_region ? 1 : 0
  bucket = module.s3-config[0].id

  policy = data.aws_iam_policy_document.s3_config_bucket_policy_doc[0].json
}

data "aws_iam_policy_document" "s3_config_bucket_policy_doc" {
  count = var.create_s3_config_bucket && var.default_aws_region == var.aws_region ? 1 : 0

  # https://docs.aws.amazon.com/config/latest/developerguide/s3-bucket-policy.html#granting-access-in-another-account

  # Base Permissions
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketAcl",
      "s3:ListBucket"
    ]
    resources = [
      module.s3-config[0].arn
    ]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_number]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
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
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_number]
    }
  }

  # Sharing with AWS Account IDs
  dynamic "statement" {
    for_each = length(var.application_account_numbers) > 0 ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "s3:GetBucketAcl",
        "s3:ListBucket"
      ]
      resources = [
        module.s3-config[0].arn
      ]
      principals {
        type        = "Service"
        identifiers = ["config.amazonaws.com"]
      }
      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = var.application_account_numbers
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.application_account_numbers) > 0 ? [1] : []
    content {
      effect  = "Allow"
      actions = ["s3:PutObject"]
      resources = [
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
      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = var.application_account_numbers
      }
    }
  }

  # Sharing with AWS Organization ID
  dynamic "statement" {
    for_each = var.organization_id != null ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "s3:GetBucketAcl",
        "s3:ListBucket"
      ]
      resources = [
        module.s3-config[0].arn
      ]
      principals {
        type        = "Service"
        identifiers = ["config.amazonaws.com"]
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
      effect  = "Allow"
      actions = ["s3:PutObject"]
      resources = [
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
      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values   = [var.organization_id]
      }
    }
  }
}

## Config Conformance Pack Bucket ##
module "s3_config_conformance_pack" {
  count = var.create_s3_config_bucket ? 1 : 0

  source = "github.com/Coalfire-CF/terraform-aws-s3?ref=v1.0.4"

  name                    = "awsconfigconforms-${var.resource_prefix}-${var.aws_region}"
  kms_master_key_id       = module.s3_kms_key[0].kms_key_arn
  attach_public_policy    = false
  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # S3 Access Logs
  logging       = true
  target_bucket = module.s3-accesslogs[0].id
  target_prefix = "config-conformance/"

  # Tags
  tags = merge(
    try(var.s3_backup_settings["config-conformance"].enable_backup, false) && length(var.s3_backup_policy) > 0 ? {
      backup_policy = var.s3_backup_policy
    } : {},
    var.s3_tags
  )
}

resource "aws_s3_bucket_policy" "conformance_pack_bucket_policy" {
  count  = var.create_s3_config_bucket && var.default_aws_region == var.aws_region ? 1 : 0
  bucket = module.s3_config_conformance_pack[0].id

  policy = data.aws_iam_policy_document.s3_config_conformance_pack_bucket_policy_doc[0].json
}

data "aws_iam_policy_document" "s3_config_conformance_pack_policy_doc" {
  count = var.create_s3_config_bucket && var.default_aws_region == var.aws_region ? 1 : 0

  # https://docs.aws.amazon.com/config/latest/developerguide/s3-bucket-policy.html#granting-access-in-another-account

  # Base Permissions
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketAcl",
      "s3:ListBucket"
    ]
    resources = [
      module.s3_config_conformance_pack[0].arn
    ]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_number]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "${module.s3_config_conformance_pack[0].arn}/*"
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
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_number]
    }
  }

  # Sharing with AWS Account IDs
  dynamic "statement" {
    for_each = length(var.application_account_numbers) > 0 ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "s3:GetBucketAcl",
        "s3:ListBucket"
      ]
      resources = [
        module.s3_config_conformance_pack[0].arn
      ]
      principals {
        type        = "Service"
        identifiers = ["config.amazonaws.com"]
      }
      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = var.application_account_numbers
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.application_account_numbers) > 0 ? [1] : []
    content {
      effect  = "Allow"
      actions = ["s3:PutObject"]
      resources = [
        "${module.s3_config_conformance_pack[0].arn}/*"
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
      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = var.application_account_numbers
      }
    }
  }

  # Sharing with AWS Organization ID
  dynamic "statement" {
    for_each = var.organization_id != null ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "s3:GetBucketAcl",
        "s3:ListBucket"
      ]
      resources = [
        module.s3_config_conformance_pack[0].arn
      ]
      principals {
        type        = "Service"
        identifiers = ["config.amazonaws.com"]
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
      effect  = "Allow"
      actions = ["s3:PutObject"]
      resources = [
        "${module.s3_config_conformance_pack[0].arn}/*"
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
      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values   = [var.organization_id]
      }
    }
  }
}