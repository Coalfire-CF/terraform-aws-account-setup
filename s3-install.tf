module "s3-installs" {
  source = "github.com/Coalfire-CF/terraform-aws-s3?ref=v1.0.0"

  name                    = "${var.resource_prefix}-${var.aws_region}-installs"
  kms_master_key_id       = module.security-core.s3_key_id
  attach_public_policy    = false
  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # S3 Access Logs
  target_bucket = module.s3-accesslogs.id
  target_prefix = "installs/"
}
