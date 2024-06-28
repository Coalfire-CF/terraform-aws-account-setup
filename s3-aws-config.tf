module "s3-config" {
  count = var.create_s3_config_bucket ? 1 : 0

  source = "github.com/Coalfire-CF/terraform-aws-s3?ref=v1.0.1"

  name                    = "${var.resource_prefix}-${var.aws_region}-config"
  kms_master_key_id       = module.s3_kms_key[0].kms_key_arn
  attach_public_policy    = false
  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # IAM 
  aws_iam_policy_document = data.aws_iam_policy_document.s3_config_bucket_policy_doc.json

  # S3 Access Logs
  logging       = true
  target_bucket = module.s3-accesslogs[0].id
  target_prefix = "config/"
}

data "aws_iam_policy_document" "s3_config_bucket_policy_doc" {
  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html
  dynamic "statement" {
    for_each = var.application_account_numbers
    content {
      effect  = "Allow"
      actions = ["s3:GetBucketAcl", "s3:ListBucket"]
      resources = [
        module.s3-config[0].arn
      ]
      principals {
        type        = "Service"
        identifiers = ["config.amazonaws.com"]
      }
    }
  }
  dynamic "statement" {
    for_each = var.application_account_numbers
    content {
      effect  = "Allow"
      actions = ["s3:PutObject*"]
      resources = [
        module.s3-config[0].arn,
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
    }

  }

}
