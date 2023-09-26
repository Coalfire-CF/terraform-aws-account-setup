module "ebs_kms_key" {
  count = var.create_ebs_kms_key ? 1 : 0

  source = "github.com/Coalfire-CF/terraform-aws-kms"

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
        "arn:${data.aws_partition.current}:iam::${var.account_number}:root"
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
        "arn:${data.aws_partition.current}:iam::${statement.value}:root"]
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
        values   = ["aws:SourceArn"]
        variable = "arn:${data.aws_partition.current}:iam::${statement.value}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
      }
    }
  }
}

module "sm_kms_key" {
  count  = var.create_sm_kms_key ? 1 : 0
  source = "github.com/Coalfire-CF/terraform-aws-kms"

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
        "arn:${data.aws_partition.current}:iam::${statement.value}:root"]
        type = "AWS"
      }
    }
  }

  statement {
    sid     = "Enable MGMT IAM User Permissions"
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      identifiers = ["arn:${data.aws_partition.current}:iam::${var.account_number}:root"]
      type        = "AWS"
    }
    resources = ["*"]
  }
}

module "backup_kms_key" {
  count  = var.create_backup_kms_key ? 1 : 0
  source = "github.com/Coalfire-CF/terraform-aws-kms"

  key_policy            = module.security-core.s3_key_iam
  kms_key_resource_type = "backup"
  resource_prefix       = var.resource_prefix
}

module "lambda_kms_key" {
  count  = var.create_lambda_kms_key ? 1 : 0
  source = "github.com/Coalfire-CF/terraform-aws-kms"

  kms_key_resource_type = "lambda"
  resource_prefix       = var.resource_prefix
}

module "rds_kms_key" {
  count  = var.create_rds_kms_key ? 1 : 0
  source = "github.com/Coalfire-CF/terraform-aws-kms"

  kms_key_resource_type = "rds"
  resource_prefix       = var.resource_prefix
}

module "additional_kms_keys" {
  source   = "github.com/Coalfire-CF/terraform-aws-kms"
  for_each = var.kms_keys

  key_policy            = each.value["policy"]
  kms_key_resource_type = each.value["name"]
  resource_prefix       = var.resource_prefix
}