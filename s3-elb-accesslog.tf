module "s3-elb-accesslogs" {
  #checkov:skip=CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
  source = "github.com/Coalfire-CF/terraform-aws-s3?ref=v1.0.0"

  name                    = "${var.resource_prefix}-${var.aws_region}-elb-accesslogs"
  attach_public_policy    = false
  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html#enable-access-logs-troubleshooting
  # KMS keys are not supported for Classic Load Balancer logging
  enable_kms = false

  # S3 Access Logs
  logging       = true
  target_bucket = module.s3-accesslogs.id
  target_prefix = "elb-accesslogs/"
}

locals {
  # Note: This is specifically for Classic Load Balancer to give write access to ELB Access Logs S3 Bucket
  # https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
  aws_lb_account_ids = {
    us-east-2     = "033677994240"
    us-east-1     = "127311923021"
    us-west-1     = "027434742980"
    us-west-2     = "797873946194"
    us-gov-west-1 = "048591011584"
    us-gov-east-1 = "190560391635"
  }
}

data "aws_iam_policy_document" "elb_accesslogs_bucket_policy" {
  statement {
    actions = ["s3:GetBucketAcl"]
    effect  = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${var.resource_prefix}-${var.aws_region}-elb-accesslogs"]
  }

  statement {
    actions = ["s3:PutObject"]
    effect  = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${var.resource_prefix}-${var.aws_region}-elb-accesslogs/*"]
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
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${local.aws_lb_account_ids[var.aws_region]}:root"]
      type        = "AWS"
    }
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.resource_prefix}-${var.aws_region}-elb-accesslogs/lb/AWSLogs/${var.account_number}/*",

    ]
  }

  dynamic "statement" {
    for_each = var.application_account_numbers
    content {
      actions = ["s3:PutObject"]
      effect  = "Allow"
      principals {
        identifiers = ["arn:${data.aws_partition.current.partition}:iam::${local.aws_lb_account_ids[var.aws_region]}:root"]
        type        = "AWS"
      }
      resources = ["arn:${data.aws_partition.current.partition}:s3:::${var.resource_prefix}-${var.aws_region}-elb-accesslogs/lb/AWSLogs/${statement.value}/*"]
    }
  }
}
