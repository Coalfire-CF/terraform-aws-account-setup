variable "aws_region" {
  description = "The AWS region to create resources in"
  type        = string
}

variable "default_aws_region" {
  description = "The default AWS region to create resources in"
  type        = string
}

variable "application_account_numbers" {
  description = "AWS account numbers for all application accounts"
  type        = list(string)
}

variable "account_number" {
  description = "The AWS account number resources are being deployed into"
  type        = string
}

variable "resource_prefix" {
  description = "The prefix for the s3 bucket names"
  type        = string
}

variable "create_cloudtrail" {
  description = "Whether or not to create cloudtrail resources"
  type        = bool
}

variable "partition" {
  type        = string
  description = "For East/west use aws or for gov cloud use aws-us-gov"
}

variable "lambda_time_zone" {
  description = "The time zone for the stopinator lambda funciton"
  default     = "US/Eastern"
  type        = string
}

variable "ssm_parameter_store_ad_users" {
  default     = "/production/mgmt/ad/users/"
  description = "The path to be used for AD users in parameter store"
  type        = string
}
variable "aws_lb_account_ids" {
  description = "https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html"
  default     = {}
}

variable "ad_secrets_manager_path" {
  description = "The path to be used for AD users in parameter store"
  type        = string
}


variable "enable_aws_config" {
  description = "Enable AWS config for this account"
  type        = bool
}

variable "config_delivery_frequency" {
  description = "AWS Config delivery frequencies"
  type        = string
  default     = "One_Hour"
}

variable "aws_backup_plan_name" {
  description = "AWS Backup plan name"
  type        = string
  default     = "fedramp-aws-backup-plan"
}

variable "backup_selection_tag_value" {
  description = "AWS Backup tag values"
  type        = string
  default     = "fedramp-daily-aws-backups"
}

variable "backup_rule_name" {
  description = "AWS Backup rule name"
  type        = string
  default     = "fedramp-aws-backup-default-rule"

}

variable "backup_vault_name" {
  description = "AWS Backup vault name"
  type        = string
  default     = "fedramp-aws-backup-vault"
}

variable "delete_after" {
  type = number
}

variable "kms_keys" {
  description = "a list of maps of KMS keys needed to be created"
  type        = list(map(string))
  default     = null
}

variable "create_s3_kms_key" {
  description = "create KMS key for S3"
  type        = bool
  default     = true
}

variable "create_ebs_kms_key" {
  description = "create KMS key for ebs"
  type        = bool
  default     = true
}

variable "create_sm_kms_key" {
  description = "create KMS key for secrets manager"
  type        = bool
  default     = true
}

variable "create_dynamo_kms_key" {
  description = "create KMS key for dynamodb"
  type        = bool
  default     = true
}

variable "create_lambda_kms_key" {
  description = "create KMS key for lamb da"
  type        = bool
  default     = true
}

variable "create_rds_kms_key" {
  description = "create KMS key for rds"
  type        = bool
  default     = true
}

variable "create_backup_kms_key" {
  description = "create KMS key for AWS Backups"
  type        = bool
  default     = true
}