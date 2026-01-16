module "security-core" {
  count = var.create_security_core ? 1 : 0

  source = "git::https://github.com/Coalfire-CF/terraform-aws-securitycore?ref=v0.1.0"

  application_account_numbers = var.application_account_numbers
  aws_region                  = var.aws_region
  resource_prefix             = var.resource_prefix

  # KMS Keys
  s3_kms_key_arn = module.s3_kms_key[0].kms_key_arn
}
