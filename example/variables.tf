variable "is_gov" {
  description = "Whether or not the environment is being deployed in GovCloud"
  type        = bool
}

variable "aws_region" {
  description = "The AWS region to create resources in"
  type        = string
}

variable "default_aws_region" {
  description = "The default AWS region to create resources in"
  type        = string
}

variable "account_number" {
  description = "The AWS account number resources are being deployed into"
  type        = string
}

variable "resource_prefix" {
  description = "The prefix for resources"
  type        = string
}

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

variable "create_packer_iam" {
  description = "Whether or not to create Packer IAM resources"
  type        = bool
  default     = false
}

variable "create_security_core" {
  description = "Whether or not to create Security Core resources"
  type        = bool
  default     = false
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

variable "ssh_key_name" {
  description = "The name of the SSH key pair to use for EC2 instances."
  type        = string
}

variable "ssh_key_secret_name" {
  description = "The name of the secret in Secrets Manager that stores the private SSH key."
  type        = string
}