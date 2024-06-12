module "security-core" {
  source = "github.com/Coalfire-CF/terraform-aws-securitycore?ref=02087ae72394cd06431efc5dbbc4bf1f7f88ad14"

  application_account_numbers = var.application_account_numbers
  aws_region                  = var.aws_region
  resource_prefix             = var.resource_prefix

  # KMS Keys
  dynamo_kms_key_arn = module.dynamo_kms_key[0].kms_key_arn
  s3_kms_key_arn     = module.s3_kms_key[0].kms_key_arn
}
