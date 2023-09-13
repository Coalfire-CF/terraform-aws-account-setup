module "config" {
  source = "github.com/Coalfire-CF/ACE-AWS-Config?ref=v0.0.4"

  aws_region         = var.aws_region
  bucket_name        = "${var.resource_prefix}-${var.default_aws_region}-aws-config"
  default_aws_region = var.default_aws_region
  delivery_frequency = var.config_delivery_frequency
  is_enabled         = var.enable_aws_config
  kms_s3_arn         = module.security-core.s3_key_arn
  resource_prefix    = var.resource_prefix
}