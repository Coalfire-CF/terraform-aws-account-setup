module "ebs_kms_key" {
  count = var.create_ebs_kms_key ? 1 : 0

  source = "github.com/Coalfire-CF/terraform-aws-kms?ref=v0.0.6"

  key_policy            = data.aws_iam_policy_document.ebs_key.json
  kms_key_resource_type = "ebs"
  resource_prefix       = var.resource_prefix
}

data "aws_iam_policy_document" "ebs_key" {

  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${var.account_number}:root"
      ]
    }
  }
  dynamic "statement" {
    for_each = var.application_account_numbers
    content {
      effect = "Allow"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
        "kms:CreateGrant",
        "kms:ListGrants",
      "kms:RevokeGrant"]
      resources = [
      "*"]
      principals {
        type = "AWS"
        identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${statement.value}:root"]
      }
    }
  }
  dynamic "statement" {
    for_each = var.application_account_numbers
    content {
      effect = "Allow"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
        "kms:CreateGrant",
        "kms:ListGrants"
      ]
      resources = [
      "*"]
      principals {
        type = "AWS"
        identifiers = [
        statement.value]
      }
      condition {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values   = ["arn:${data.aws_partition.current.partition}:iam::${statement.value}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
      }
    }
  }
}

module "sm_kms_key" {
  count  = var.create_sm_kms_key ? 1 : 0
  source = "github.com/Coalfire-CF/terraform-aws-kms?ref=v0.0.6"

  key_policy            = data.aws_iam_policy_document.secrets_manager_key.json
  kms_key_resource_type = "sm"
  resource_prefix       = var.resource_prefix
}

data "aws_iam_policy_document" "secrets_manager_key" {
  dynamic "statement" {
    for_each = var.application_account_numbers
    content {
      effect = "Allow"
      actions = [
      "kms:*"]
      resources = [
      "*"]
      principals {
        identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${statement.value}:root"]
        type = "AWS"
      }
    }
  }

  statement {
    sid     = "Enable MGMT IAM User Permissions"
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${var.account_number}:root"]
      type        = "AWS"
    }
    resources = ["*"]
  }
}

module "backup_kms_key" {
  count  = var.create_backup_kms_key ? 1 : 0
  source = "github.com/Coalfire-CF/terraform-aws-kms?ref=v0.0.6"

  key_policy            = module.security-core.s3_key_iam
  kms_key_resource_type = "backup"
  resource_prefix       = var.resource_prefix
}

module "lambda_kms_key" {
  count  = var.create_lambda_kms_key ? 1 : 0
  source = "github.com/Coalfire-CF/terraform-aws-kms?ref=v0.0.6"

  kms_key_resource_type = "lambda"
  resource_prefix       = var.resource_prefix
}

module "rds_kms_key" {
  count  = var.create_rds_kms_key ? 1 : 0
  source = "github.com/Coalfire-CF/terraform-aws-kms?ref=v0.0.6"

  kms_key_resource_type = "rds"
  resource_prefix       = var.resource_prefix
}

module "cloudwatch_kms_key" {
  count  = var.create_cloudwatch_kms_key ? 1 : 0
  source = "github.com/Coalfire-CF/terraform-aws-kms?ref=v0.0.6"

  kms_key_resource_type = "cloudwatch"
  resource_prefix       = var.resource_prefix
  key_policy            = data.aws_iam_policy_document.cloudwatch_key.json
}

module "sns_kms_key" {
  count  = var.create_cloudtrail && var.default_aws_region == var.aws_region ? 1 : 0
  source = "github.com/Coalfire-CF/terraform-aws-kms?ref=v0.0.6"

  kms_key_resource_type = "sns"
  resource_prefix       = var.resource_prefix
  key_policy            = data.aws_iam_policy_document.sns_key.json
}


module "additional_kms_keys" {
  source   = "github.com/Coalfire-CF/terraform-aws-kms?ref=v0.0.6"
  for_each = { for key in var.additional_kms_keys : key.name => key }

  key_policy            = each.value.policy
  kms_key_resource_type = each.value.name
  resource_prefix       = var.resource_prefix
}

data "aws_iam_policy_document" "cloudwatch_key" {

  dynamic "statement" {
    for_each = var.application_account_numbers
    content {
      effect = "Allow"
      actions = [
      "kms:*"]
      resources = [
      "*"]
      principals {
        identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${statement.value}:root"]
        type = "AWS"
      }
    }
  }

  statement {
    effect = "Allow"
    actions = [
    "kms:*"]
    resources = [
    "*"]
    principals {
      type = "AWS"
      identifiers = [
      "arn:${data.aws_partition.current.partition}:iam::${var.account_number}:root"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [
    "*"]

    principals {
      type = "Service"
      identifiers = [
      "delivery.logs.amazonaws.com"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [
    "*"]

    principals {
      type = "Service"
      identifiers = [
      "logs.${var.default_aws_region}.amazonaws.com"]
    }
  }

  statement {
    sid    = "Enable CloudTrail Encrypt Permissions"
    effect = "Allow"
    actions = [
    "kms:GenerateDataKey*"]
    resources = [
    "*"]
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values = [
      "arn:${data.aws_partition.current.partition}:cloudtrail:*:${var.account_number}:trail/*"]
    }
    principals {
      type = "Service"
      identifiers = [
      "cloudtrail.amazonaws.com"]
    }
  }

  dynamic "statement" {
    for_each = var.application_account_numbers
    content {
      effect = "Allow"
      actions = [
      "kms:GenerateDataKey*"]
      resources = [
      "*"]
      condition {
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:cloudtrail:arn"
        values = [
        "arn:${data.aws_partition.current.partition}:cloudtrail:*:${statement.value}:trail/*"]
      }
      principals {
        type = "Service"
        identifiers = [
        "cloudtrail.amazonaws.com"]
      }
    }
  }
}

data "aws_iam_policy_document" "sns_key" {
  dynamic "statement" {
    for_each = var.application_account_numbers
    content {
      effect = "Allow"
      actions = [
      "kms:*"]
      resources = [
      "*"]
      principals {
        identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${statement.value}:root"]
        type = "AWS"
      }
    }
  }

  statement {
    sid     = "Enable MGMT IAM User Permissions"
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${var.account_number}:root"]
      type        = "AWS"
    }
    resources = ["*"]
  }

  statement {
    sid    = "Allow CloudTrail to use the key"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]
    resources = ["*"]
    principals {
      type = "Service"
      identifiers = [
      "cloudtrail.amazonaws.com"]
    }
  }
}