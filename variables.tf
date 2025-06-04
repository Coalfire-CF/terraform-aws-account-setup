### General ###
variable "aws_region" {
  description = "The AWS region to create resources in"
  type        = string
}

variable "default_aws_region" {
  description = "The default AWS region to create resources in"
  type        = string
}

variable "application_account_numbers" {
  description = "AWS account numbers for all application accounts that might need shared access to resources like KMS keys"
  type        = list(string)
  default     = []
}

variable "account_number" {
  description = "The AWS account number resources are being deployed into"
  type        = string
}

variable "resource_prefix" {
  description = "The prefix for resources"
  type        = string
}

variable "is_organization" {
  description = "Whether or not to enable certain settings for AWS Organization"
  type        = bool
  default     = true
}

variable "organization_id" {
  description = "AWS Organization ID"
  type        = string
  default     = null
}

### CloudTrail ###
variable "create_cloudtrail" {
  description = "Whether or not to create cloudtrail resources"
  type        = bool
  default     = false
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "The number of days to retain Cloudwatch logs"
  type        = number
  default     = 30
}

### AWS AutoScale IAM Role ###
variable "create_autoscale_role" {
  description = "Create AWS Autoscale IAM Role (needed for any autoscaling aws resources)"
  type        = bool
  default     = true #If AWSServiceRoleForAutoScaling role already exists in environment will have to set this var to false where the module is called
}

### KMS ###
variable "additional_kms_keys" {
  description = "a list of maps of any additional KMS keys that need to be created"
  type        = list(map(string))
  default     = []
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

variable "create_sns_kms_key" {
  description = "create KMS key for SNS"
  type        = bool
  default     = true
}

variable "create_sm_kms_key" {
  description = "create KMS key for secrets manager"
  type        = bool
  default     = true
}

variable "create_lambda_kms_key" {
  description = "create KMS key for lambda"
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

variable "create_cloudwatch_kms_key" {
  description = "create KMS key for AWS Cloudwatch"
  type        = bool
  default     = true
}

variable "create_config_kms_key" {
  description = "create KMS key for AWS Cloudwatch"
  type        = bool
  default     = true
}

variable "create_ecr_kms_key" {
  description = "create KMS key for ECR"
  type        = bool
  default     = true
}

variable "create_sqs_kms_key" {
  description = "create KMS key for SQS"
  type        = bool
  default     = true
}

variable "create_nfw_kms_key" {
  description = "create KMS key for NFW"
  type        = bool
  default     = true
}

variable "kms_multi_region" {
  description = "Indicates whether the KMS key is a multi-Region (true) or regional (false) key."
  type        = bool
  default     = false
}

### S3 ###
variable "create_s3_accesslogs_bucket" {
  description = "Create S3 Access Logs Bucket"
  type        = bool
  default     = true # S3 access logs MUST be in the same region and AWS Account, cross-account logging is NOT supported
}

variable "create_s3_backups_bucket" {
  description = "Create S3 Backups Bucket"
  type        = bool
  default     = true
}

variable "create_s3_elb_accesslogs_bucket" {
  description = "Create S3 ELB Access Logs Bucket"
  type        = bool
  default     = true # ELB Access Logs must be in the same region, but the bucket and load balancer can be in different accounts
}

variable "create_s3_fedrampdoc_bucket" {
  description = "Create S3 FedRAMP Documents Bucket"
  type        = bool
  default     = true
}

variable "create_s3_installs_bucket" {
  description = "Create S3 Installs Bucket"
  type        = bool
  default     = true
}

variable "create_s3_config_bucket" {
  description = "Create S3 AWS Config Bucket for conformance pack storage"
  type        = bool
  default     = true
}

variable "s3_backup_settings" {
  description = "Map of S3 bucket types to their backup settings"
  type = map(object({
    enable_backup = bool
  }))
  default = {
    accesslogs = {
      enable_backup = false # Assuming that a SIEM will ingest and store these logs
    }
    elb-accesslogs = {
      enable_backup = false # Assuming that a SIEM will ingest and store these logs
    }
    backups = {
      enable_backup = true
    }
    installs = {
      enable_backup = true
    }
    fedrampdoc = {
      enable_backup = true
    }
    cloudtrail = {
      enable_backup = false # Assuming that a SIEM will ingest and store these logs
    }
    config = {
      enable_backup = true
    }
  }
}

variable "s3_backup_policy" {
  description = "S3 backup policy to use for S3 buckets in conjunction with AWS Backups, should match an existing policy"
  type        = string
  default     = "" # What you specified in AWS Backups pak, may look like "aws-backup-${var.resource_prefix}-default-policy"
}

variable "s3_tags" {
  description = "Tags to be applied to S3 buckets"
  type        = map(any)
  default     = {}
}

### Misc ###
# Note: To my knowledge, it's not a common configuration to have Terraform state across multiple accounts, so this will default to false
variable "create_security_core" {
  description = "Whether or not to create Security Core resources"
  type        = bool
  default     = false
}

# In normal usage only one account builds/holds the AMIs while it is shared to other account IDs (provided as variables to Packer)
# This is to prevent excessive numbers of AMIs in each account.
variable "create_packer_iam" {
  description = "Whether or not to create Packer IAM resources"
  type        = bool
  default     = false
}

variable "packer_additional_iam_principal_arns" {
  description = "List of IAM Principal ARNs allowed to assume the Packer IAM Role"
  type        = list(string)
  default     = []
}