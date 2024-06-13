module "security-core" {
  count = var.create_security_core ? 1 : 0

  source = "github.com/Coalfire-CF/terraform-aws-securitycore?ref=51d3d3f4cfafb408ee62e5f289a2097edc1aaca1"

  application_account_numbers = var.application_account_numbers
  aws_region                  = var.aws_region
  resource_prefix             = var.resource_prefix

  # KMS Keys
  dynamo_kms_key_arn = module.dynamo_kms_key[0].kms_key_arn
  s3_kms_key_arn     = module.s3_kms_key[0].kms_key_arn
}
