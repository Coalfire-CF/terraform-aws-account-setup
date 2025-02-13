module "s3-installs" {
  count = var.create_s3_installs_bucket ? 1 : 0

  source = "github.com/Coalfire-CF/terraform-aws-s3?ref=v1.0.4"

  name                    = "${var.resource_prefix}-${var.aws_region}-installs"
  kms_master_key_id       = module.s3_kms_key[0].kms_key_arn
  attach_public_policy    = false
  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # S3 Access Logs
  logging       = true
  target_bucket = module.s3-accesslogs[0].id
  target_prefix = "installs/"

  # Tags
  tags = merge(
    try(var.s3_backup_settings["installs"].enable_backup, false) && length(var.s3_backup_policy) > 0 ? {
      backup_policy = var.s3_backup_policy
    } : {},
    var.s3_tags
  )
}
