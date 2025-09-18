# To reduce code deduplication, we'll define a common policy used by all KMS keys and merge them using "source_policy_documents"
# This also makes it easier to parse the policy that is directly related to a service key.
data "aws_iam_policy_document" "kms_base_and_sharing_permissions" {
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

  # Sharing KMS Key using Account IDs
  dynamic "statement" {
    for_each = !var.is_organization ? toset(var.application_account_numbers) : []
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

  # Sharing KMS Key using AWS Organization ID
  dynamic "statement" {
    for_each = var.is_organization && var.organization_id != null ? [1] : []
    content {
      effect    = "Allow"
      actions   = ["kms:*"]
      resources = ["*"]
      principals {
        type        = "AWS"
        identifiers = ["*"]
      }
      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values   = [var.organization_id]
      }
    }
  }
}

module "ebs_kms_key" {
  count = var.create_ebs_kms_key ? 1 : 0

  source = "git::https://github.com/Coalfire-CF/terraform-aws-kms?ref=v1.0.1"

  key_policy            = data.aws_iam_policy_document.ebs_key[0].json
  kms_key_resource_type = "ebs"
  resource_prefix       = var.resource_prefix
  multi_region          = var.kms_multi_region

}

data "aws_iam_policy_document" "ebs_key" {
  count = (var.create_ebs_kms_key || var.create_autoscale_role) ? 1 : 0

  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html

  source_policy_documents = [
    data.aws_iam_policy_document.kms_base_and_sharing_permissions.json
  ]

  ################################################################################
  # Auto-Scaling Group
  ################################################################################
  # AWS Account must have AWSServiceRoleForAutoScaling Role which is created by variable create_autoscale_role
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

  source = "git::https://github.com/Coalfire-CF/terraform-aws-kms?ref=v1.0.1"

  key_policy            = data.aws_iam_policy_document.s3_key[0].json
  kms_key_resource_type = "s3"
  resource_prefix       = var.resource_prefix
  multi_region          = var.kms_multi_region
}

data "aws_iam_policy_document" "s3_key" {
  count = var.create_s3_kms_key ? 1 : 0

  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html

  source_policy_documents = [
    data.aws_iam_policy_document.kms_base_and_sharing_permissions.json
  ]

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
    for_each = toset(var.application_account_numbers)
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

  source = "git::https://github.com/Coalfire-CF/terraform-aws-kms?ref=v1.0.1"

  key_policy            = data.aws_iam_policy_document.sns_key[0].json
  kms_key_resource_type = "sns"
  resource_prefix       = var.resource_prefix
  multi_region          = var.kms_multi_region
}

data "aws_iam_policy_document" "sns_key" {
  count = var.create_sns_kms_key ? 1 : 0

  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html

  source_policy_documents = [
    data.aws_iam_policy_document.kms_base_and_sharing_permissions.json
  ]
}

module "sm_kms_key" {
  count  = var.create_sm_kms_key ? 1 : 0
  source = "git::https://github.com/Coalfire-CF/terraform-aws-kms?ref=v1.0.1"

  key_policy            = data.aws_iam_policy_document.secrets_manager_key[0].json
  kms_key_resource_type = "sm"
  resource_prefix       = var.resource_prefix
  multi_region          = var.kms_multi_region
}

data "aws_iam_policy_document" "secrets_manager_key" {
  count = var.create_sm_kms_key ? 1 : 0

  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html

  source_policy_documents = [
    data.aws_iam_policy_document.kms_base_and_sharing_permissions.json
  ]
}

module "backup_kms_key" {
  count  = var.create_backup_kms_key ? 1 : 0
  source = "git::https://github.com/Coalfire-CF/terraform-aws-kms?ref=v1.0.1"

  key_policy            = data.aws_iam_policy_document.s3_key[0].json
  kms_key_resource_type = "backup"
  resource_prefix       = var.resource_prefix
  multi_region          = var.kms_multi_region
}

module "lambda_kms_key" {
  count  = var.create_lambda_kms_key ? 1 : 0
  source = "git::https://github.com/Coalfire-CF/terraform-aws-kms?ref=v1.0.1"

  kms_key_resource_type = "lambda"
  key_policy            = data.aws_iam_policy_document.kms_base_and_sharing_permissions.json
  resource_prefix       = var.resource_prefix
  multi_region          = var.kms_multi_region
}

module "rds_kms_key" {
  count  = var.create_rds_kms_key ? 1 : 0
  source = "git::https://github.com/Coalfire-CF/terraform-aws-kms?ref=v1.0.1"

  kms_key_resource_type = "rds"
  key_policy            = data.aws_iam_policy_document.kms_base_and_sharing_permissions.json
  resource_prefix       = var.resource_prefix
  multi_region          = var.kms_multi_region
}

module "cloudwatch_kms_key" {
  count  = var.create_cloudwatch_kms_key ? 1 : 0
  source = "git::https://github.com/Coalfire-CF/terraform-aws-kms?ref=v1.0.1"

  kms_key_resource_type = "cloudwatch"
  resource_prefix       = var.resource_prefix
  key_policy            = data.aws_iam_policy_document.cloudwatch_key[0].json
  multi_region          = var.kms_multi_region
}

data "aws_iam_policy_document" "cloudwatch_key" {
  count = var.create_cloudwatch_kms_key ? 1 : 0

  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html

  source_policy_documents = [
    data.aws_iam_policy_document.kms_base_and_sharing_permissions.json
  ]

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
    for_each = toset(var.application_account_numbers)
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

## Adding default_key_policy
# In your kms-iam.tf file in the module
module "default_kms_key" {
  count  = var.create_default_kms_key ? 1 : 0
  source = "git::https://github.com/Coalfire-CF/terraform-aws-kms?ref=v1.0.1"

  key_policy            = data.aws_iam_policy_document.default_key_policy.json
  kms_key_resource_type = "default-key-policy"
  resource_prefix       = var.resource_prefix
  multi_region          = var.kms_multi_region
}

module "additional_kms_keys" {
  source   = "git::https://github.com/Coalfire-CF/terraform-aws-kms?ref=v1.0.1"
  for_each = { for key in var.additional_kms_keys : key.name => key }

  key_policy            = data.aws_iam_policy_document.additional_kms_keys[each.key].json
  kms_key_resource_type = each.value.name
  resource_prefix       = var.resource_prefix
  multi_region          = var.kms_multi_region
}

data "aws_iam_policy_document" "additional_kms_keys" {
  # This just merges the provided key policies with the base/sharing policy
  for_each = { for key in var.additional_kms_keys : key.name => key }

  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html

  source_policy_documents = [
    data.aws_iam_policy_document.kms_base_and_sharing_permissions.json,
    each.value.policy,
  ]
}

module "config_kms_key" {
  count  = var.create_config_kms_key ? 1 : 0
  source = "git::https://github.com/Coalfire-CF/terraform-aws-kms?ref=v1.1.3"

  kms_key_resource_type = "config"
  resource_prefix       = var.resource_prefix
  key_policy            = data.aws_iam_policy_document.config_key[0].json
  multi_region          = var.kms_multi_region
}

data "aws_iam_policy_document" "config_key" {
  count = var.create_config_kms_key ? 1 : 0

  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html

  source_policy_documents = [
    data.aws_iam_policy_document.kms_base_and_sharing_permissions.json
  ]

  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

module "ecr_kms_key" {
  count = var.create_ecr_kms_key ? 1 : 0

  source                = "git::https://github.com/Coalfire-CF/terraform-aws-kms?ref=v1.0.1"
  resource_prefix       = var.resource_prefix
  kms_key_resource_type = "ecr"
  key_policy            = data.aws_iam_policy_document.ecr_kms_policy[0].json
  multi_region          = var.kms_multi_region
}

data "aws_iam_policy_document" "ecr_kms_policy" {
  count = var.create_ecr_kms_key ? 1 : 0

  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html

  source_policy_documents = [
    data.aws_iam_policy_document.kms_base_and_sharing_permissions.json
  ]

  statement {
    effect    = "Allow"
    actions   = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["ecr.amazonaws.com"]
    }
  }
}

module "sqs_kms_key" {
  count = var.create_sqs_kms_key ? 1 : 0

  source                = "git::https://github.com/Coalfire-CF/terraform-aws-kms?ref=v1.0.1"
  resource_prefix       = var.resource_prefix
  kms_key_resource_type = "sqs"
  key_policy            = data.aws_iam_policy_document.sqs_key[0].json
  multi_region          = var.kms_multi_region
}

data "aws_iam_policy_document" "sqs_key" {
  count = var.create_sqs_kms_key ? 1 : 0

  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html

  source_policy_documents = [
    data.aws_iam_policy_document.kms_base_and_sharing_permissions.json
  ]

  statement {
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    resources = ["*"]
  }
}

module "nfw_kms_key" {
  count = var.create_nfw_kms_key ? 1 : 0

  source = "git::https://github.com/Coalfire-CF/terraform-aws-kms?ref=v1.0.1"

  key_policy            = data.aws_iam_policy_document.kms_base_and_sharing_permissions.json
  kms_key_resource_type = "nfw"
  resource_prefix       = var.resource_prefix
  multi_region          = var.kms_multi_region
}
