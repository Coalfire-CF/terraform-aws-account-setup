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

variable "cloudtrail_name" {
  description = "(Optional) custom name for the Cloudtrail resource; if left undefined, a default name is created"
  type        = string
  default     = null
}

variable "cloudtrail_log_group_name" {
  description = "(Optional) custom name for the Cloudtrail log group in Cloudwatch; if left undefined, a default name is created"
  type        = string
  default     = null
}

variable "cloudtrail_bucket_name" {
  description = "(Optional) custom name for the Cloudtrail S3 Bucket; if left undefined, a default name is created"
  type        = string
  default     = null
}

variable "cloudtrail_iam_role_name" {
  description = "(Optional) custom name for the Cloudtrail to Cloudwatch IAM role; if left undefined, a default name is created"
  type        = string
  default     = null
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

variable "create_default_kms_key" {
  description = "create default kms key"
  type        = bool
  default     = true
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

variable "accesslogs_bucket_name" {
  description = "(Optional) custom name for the access logs S3 bucket; if left undefined, a default name is created"
  type        = string
  default     = null
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

variable "elb_accesslogs_bucket_name" {
  description = "(Optional) custom name for the ELB access logs S3 bucket; if left undefined, a default name is created"
  type        = string
  default     = null
}

variable "create_s3_fedrampdoc_bucket" {
  description = "Create S3 FedRAMP Documents Bucket"
  type        = bool
  default     = true
}

variable "fedrampdoc_bucket_name" {
  description = "(Optional) custom name for the FedRAMP docs S3 bucket; if left undefined, a default name is created"
  type        = string
  default     = null
}

variable "create_s3_installs_bucket" {
  description = "Create S3 Installs Bucket"
  type        = bool
  default     = true
}

variable "installs_bucket_name" {
  description = "(Optional) custom name for the installs S3 bucket; if left undefined, a default name is created"
  type        = string
  default     = null
}

variable "create_s3_config_bucket" {
  description = "Create S3 AWS Config Bucket for conformance pack storage"
  type        = bool
  default     = true
}

variable "config_bucket_name" {
  description = "(Optional) custom name for the configuration S3 bucket; if left undefined, a default name is created"
  type        = string
  default     = null
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
    config-conformance = {
      enable_backup = true
    }
  }
}

variable "backups_bucket_name" {
  description = "(Optional) custom name for the backups S3 bucket; if left undefined, a default name is created"
  type        = string
  default     = null
}

variable "s3_backup_policy" {
  description = "S3 backup policy to use for S3 buckets in conjunction with AWS Backups, should match an existing policy"
  type        = string
  default     = "aws-backup-minimum-compliance" # Do not change this unless you want to change it everywhere else
}

variable "s3_tags" {
  description = "Tags to be applied to S3 buckets"
  type        = map(any)
  default     = {}
}

variable "config_cross_account_ids" {
  type        = list(string)
  description = "AWS account IDs allowed cross-account access to the Config bucket"
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

variable "packer_iam_role_name" {
  description = "(Optional) custom name for the Packer IAM role; if left undefined, a default name is created"
  type        = string
  default     = null
}

variable "packer_iam_policy_name" {
  description = "(Optional) custom name for the Packer IAM policy; if left undefined, a default name is created"
  type        = string
  default     = null
}

variable "packer_iam_instanceprofile_name" {
  description = "(Optional) custom name for the Packer IAM instance profile; if left undefined, a default name is created"
  type        = string
  default     = null
}

variable "packer_s3_kmsgrant_name" {
  description = "(Optional) custom name for the KMS grant allowing Packer to access the S3 bucket KMS key; if left undefined, a default name is created"
  type        = string
  default     = null
}

variable "packer_ebs_kmsgrant_name" {
  description = "(Optional) custom name for the KMS grant allowing Packer to access the EBS KMS key; if left undefined, a default name is created"
  type        = string
  default     = null
}

variable "packer_additional_iam_principal_arns" {
  description = "List of IAM Principal ARNs allowed to assume the Packer IAM Role"
  type        = list(string)
  default     = []
}

variable "ssh_key_name" {
  description = "The name of the SSH key pair to use for EC2 instances."
  type        = string
  default     = "fedramp-mgmt-gov-key"
}

variable "ssh_key_secret_name" {
  description = "The name of the secret in Secrets Manager that stores the private SSH key."
  type        = string
  default     = "/management/fedramp-mgmt-gov/ec2-key-pair"
}
