module "s3-installs" {
  source = "github.com/Coalfire-CF/ACE-AWS-S3?ref=draftv0.0.2"

  name                    = "${var.resource_prefix}-${var.aws_region}-installs"
  kms_master_key_id       = module.security-core.s3_key_id
  attach_public_policy    = false
  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}