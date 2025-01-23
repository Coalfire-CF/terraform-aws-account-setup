module "dynamo_kms_key" {
  count = var.create_dynamo_kms_key ? 1 : 0

  source = "github.com/Coalfire-CF/terraform-aws-kms?ref=v0.0.6"

  key_policy            = data.aws_iam_policy_document.dynamo_key.json
  kms_key_resource_type = "dynamodb"
  resource_prefix       = var.resource_prefix
}

data "aws_iam_policy_document" "dynamo_key" {
  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html

  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${var.account_number}:root"]
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
      "kms:CreateGrant",
      "kms:ListGrants"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${var.account_number}:root"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["dynamodb.*.amazonaws.com"]

    }
  }
}

module "ebs_kms_key" {
  count = var.create_ebs_kms_key ? 1 : 0

  source = "github.com/Coalfire-CF/terraform-aws-kms?ref=v0.0.6"

  key_policy            = data.aws_iam_policy_document.ebs_key.json
  kms_key_resource_type = "ebs"
  resource_prefix       = var.resource_prefix

  depends_on = [aws_iam_service_linked_role.autoscale]
}

data "aws_iam_policy_document" "ebs_key" {
  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html

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
    for_each = { for idx, account in var.application_account_numbers : idx => account if account != "" }
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
        "kms:RevokeGrant"
      ]
      resources = ["*"]
      principals {
        type        = "AWS"
        identifiers = ["arn:${data.aws_partition.current.partition}:iam::${statement.value}:root"]
      }
    }
  }

  ################################################################################
  # Auto-Scaling Group
  ################################################################################

  # https://docs.aws.amazon.com/autoscaling/ec2/userguide/key-policy-requirements-EBS-encryption.html#policy-example-cmk-access
  statement {
    effect = "Allow"
    sid    = "Allow service-linked role use of the customer managed key"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${var.account_number}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
    }
    resources = ["*"]
  }

  statement {
    effect  = "Allow"
    sid     = "Allow attachment of persistent resources"
    actions = ["kms:CreateGrant"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${var.account_number}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
    }
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = [true]
    }
  }
}

module "s3_kms_key" {
  count = var.create_s3_kms_key ? 1 : 0

  source = "github.com/Coalfire-CF/terraform-aws-kms?ref=v0.0.6"

  key_policy            = data.aws_iam_policy_document.s3_key.json
  kms_key_resource_type = "s3"
  resource_prefix       = var.resource_prefix
}

data "aws_iam_policy_document" "s3_key" {
  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html

  dynamic "statement" {
    for_each = { for idx, account in var.application_account_numbers : idx => account if account != "" }
    content {
      effect    = "Allow"
      actions   = ["kms:*"]
      resources = ["*"]
      principals {
        identifiers = ["arn:${data.aws_partition.current.partition}:iam::${statement.value}:root"]
        type        = "AWS"
      }
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${var.account_number}:root"]
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
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
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
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.aws_region}.amazonaws.com"]
    }
  }

  statement {
    sid       = "Enable CloudTrail Encrypt Permissions"
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey*"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:*:${var.account_number}:trail/*"]
    }
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }

  dynamic "statement" {
    for_each = { for idx, account in var.application_account_numbers : idx => account if account != "" }
    content {
      effect    = "Allow"
      actions   = ["kms:GenerateDataKey*"]
      resources = ["*"]
      condition {
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:cloudtrail:arn"
        values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:*:${statement.value}:trail/*"]
      }
      principals {
        type        = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }
    }
  }
}

module "sns_kms_key" {
  count = var.create_sns_kms_key ? 1 : 0

  source = "github.com/Coalfire-CF/terraform-aws-kms?ref=v0.0.6"

  key_policy            = data.aws_iam_policy_document.sns_key.json
  kms_key_resource_type = "sns"
  resource_prefix       = var.resource_prefix
}

data "aws_iam_policy_document" "sns_key" {
  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html

  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${var.account_number}:root"]
    }
  }
  dynamic "statement" {
    for_each = { for idx, account in var.application_account_numbers : idx => account if account != "" }
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
        "kms:RevokeGrant"
      ]
      resources = ["*"]
      principals {
        type        = "AWS"
        identifiers = ["arn:${data.aws_partition.current.partition}:iam::${statement.value}:root"]
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
  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html

  dynamic "statement" {
    for_each = { for idx, account in var.application_account_numbers : idx => account if account != "" }
    content {
      effect    = "Allow"
      actions   = ["kms:*"]
      resources = ["*"]
      principals {
        identifiers = ["arn:${data.aws_partition.current.partition}:iam::${statement.value}:root"]
        type        = "AWS"
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

  key_policy            = data.aws_iam_policy_document.s3_key.json
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

module "additional_kms_keys" {
  source   = "github.com/Coalfire-CF/terraform-aws-kms?ref=v0.0.6"
  for_each = { for key in var.additional_kms_keys : key.name => key }

  key_policy            = each.value.policy
  kms_key_resource_type = each.value.name
  resource_prefix       = var.resource_prefix
}

data "aws_iam_policy_document" "cloudwatch_key" {
  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html

  dynamic "statement" {
    for_each = { for idx, account in var.application_account_numbers : idx => account if account != "" }
    content {
      effect    = "Allow"
      actions   = ["kms:*"]
      resources = ["*"]
      principals {
        identifiers = ["arn:${data.aws_partition.current.partition}:iam::${statement.value}:root"]
        type        = "AWS"
      }
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${var.account_number}:root"]
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
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
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
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.default_aws_region}.amazonaws.com"]
    }
  }

  statement {
    sid       = "Enable CloudTrail Encrypt Permissions"
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey*"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:*:${var.account_number}:trail/*"]
    }
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }

  dynamic "statement" {
    for_each = { for idx, account in var.application_account_numbers : idx => account if account != "" }
    content {
      effect    = "Allow"
      actions   = ["kms:GenerateDataKey*"]
      resources = ["*"]
      condition {
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:cloudtrail:arn"
        values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:*:${statement.value}:trail/*"]
      }
      principals {
        type        = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }
    }
  }
}

module "config_kms_key" {
  count  = var.create_config_kms_key ? 1 : 0
  source = "github.com/Coalfire-CF/terraform-aws-kms?ref=v0.0.6"

  kms_key_resource_type = "config"
  resource_prefix       = var.resource_prefix
  key_policy            = data.aws_iam_policy_document.config_key.json
}

data "aws_iam_policy_document" "config_key" {
  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html

  dynamic "statement" {
    for_each = { for idx, account in var.application_account_numbers : idx => account if account != "" }
    content {
      effect    = "Allow"
      actions   = ["kms:*"]
      resources = ["*"]
      principals {
        type        = "Service"
        identifiers = ["config.amazonaws.com"]
      }
    }
  }

  dynamic "statement" {
    for_each = { for idx, account in var.application_account_numbers : idx => account if account != "" }
    content {
      effect    = "Allow"
      actions   = ["kms:*"]
      resources = ["*"]
      principals {
        identifiers = ["arn:${data.aws_partition.current.partition}:iam::${statement.value}:root"]
        type        = "AWS"
      }
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${var.account_number}:root"]
    }
  }
}