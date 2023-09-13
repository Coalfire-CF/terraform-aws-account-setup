module "security-core" {
  source = "github.com/Coalfire-CF/ACE-AWS-SecurityCore?ref=draftv0.0.3"

  account_number              = var.account_number
  application_account_numbers = var.application_account_numbers
  aws_region                  = var.aws_region
  resource_prefix             = var.resource_prefix
}