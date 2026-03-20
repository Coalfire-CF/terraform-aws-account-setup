module "account-setup" {
  source = "git::https://github.com/Coalfire-CF/terraform-aws-account-setup.git?ref=vX.X.X"

  providers = {
    aws = aws.mgmt
  }

  aws_region         = var.aws_region
  default_aws_region = var.default_aws_region
  account_number     = var.account_number
  resource_prefix    = var.resource_prefix

  create_autoscale_role = var.create_autoscaling_role

  ### Cloudtrail ###
  create_cloudtrail                      = var.create_cloudtrail
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days

  ### Secrets Manager ### (EC2 Keypair) 
  ssh_key_name        = var.ssh_key_name
  ssh_key_secret_name = var.ssh_key_secret_name

  ### Packer ###
  create_packer_iam = var.create_packer_iam # Packer AMIs will be built and kept on this account and shared with other accounts (share accounts is provided to Packer as a variable at build time)

  ### Terraform ###
  create_security_core = var.create_security_core # Terraform state will be kept on this account

  ### Sharing ###
  is_organization = var.is_organization # Should be "false" if setting "application_account_numbers"
  organization_id = var.organization_id

  ### AWS Backup ###
  s3_backup_policy = "aws-backup-minimum-compliance"

  ## KMS ### 
  additional_kms_keys = [
    {
      name   = "kinesis_firehose" # Typically used with Splunk
      policy = data.aws_iam_policy_document.default_key_policy.json
    },
    {
      name   = "iam_identity_center" # Remove if not using IAM Identity Center
      policy = data.aws_iam_policy_document.default_key_policy.json
    },
  ]

  config_cross_account_ids = local.share_accounts

}