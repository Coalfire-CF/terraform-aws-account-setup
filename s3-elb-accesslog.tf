module "s3-elb-accesslogs" {
  count = var.create_s3_elb_accesslogs_bucket ? 1 : 0

  #checkov:skip=CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
  source = "github.com/Coalfire-CF/terraform-aws-s3?ref=v1.0.4"

  name                    = local.elb_accesslogs_bucket_name
  attach_public_policy    = false
  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html#enable-access-logs-troubleshooting
  # KMS keys are not supported for Classic Load Balancer logging
  enable_kms = false

  # S3 Access Logs
  logging       = true
  target_bucket = module.s3-accesslogs[0].id
  target_prefix = "elb-accesslogs/"

  # Bucket Policy
  bucket_policy           = true
  aws_iam_policy_document = data.aws_iam_policy_document.elb_accesslogs_bucket_policy.json

  # Tags
  tags = merge(
    try(var.s3_backup_settings["elb-accesslogs"].enable_backup, false) && length(var.s3_backup_policy) > 0 ? {
      backup_policy = var.s3_backup_policy
    } : {},
    var.s3_tags
  )
}
# https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
data "aws_elb_service_account" "main" {}

data "aws_iam_policy_document" "elb_accesslogs_bucket_policy" {
  statement {
    actions = ["s3:GetBucketAcl"]
    effect  = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${local.elb_accesslogs_bucket_name}"]
  }

  statement {
    actions = ["s3:PutObject"]
    effect  = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${local.elb_accesslogs_bucket_name}/*"]
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
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_elb_service_account.main.id}:root"]
      type        = "AWS"
    }
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${local.elb_accesslogs_bucket_name}/lb/AWSLogs/${var.account_number}/*",
      "arn:${data.aws_partition.current.partition}:s3:::${local.elb_accesslogs_bucket_name}/AWSLogs/${var.account_number}/*"
    ]
  }

  # Sharing using Account IDs
  dynamic "statement" {
    for_each = toset(var.application_account_numbers)
    content {
      actions = ["s3:PutObject"]
      effect  = "Allow"
      principals {
        identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_elb_service_account.main.id}:root"]
        type        = "AWS"
      }
      resources = ["arn:${data.aws_partition.current.partition}:s3:::${local.elb_accesslogs_bucket_name}/lb/AWSLogs/${statement.value}/*"]
    }
  }

  # Sharing using AWS Organization ID
  dynamic "statement" {
    for_each = var.organization_id != null ? [1] : []
    content {
      actions = ["s3:PutObject"]
      effect  = "Allow"
      principals {
        identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_elb_service_account.main.id}:root"]
        type        = "AWS"
      }
      resources = ["arn:${data.aws_partition.current.partition}:s3:::${local.elb_accesslogs_bucket_name}/lb/AWSLogs/*"]
      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values   = [var.organization_id]
      }
    }
  }
}
