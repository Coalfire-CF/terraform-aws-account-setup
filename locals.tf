locals {
  # Where the user did not specify values for custom resource names, set resource names to default values
  cloudtrail_name                 = var.cloudtrail_name != null ? var.cloudtrail_name : "${var.resource_prefix}-cloudtrail"
  cloudtrail_bucket_name          = var.cloudtrail_bucket_name != null ? var.cloudtrail_bucket_name : "${var.resource_prefix}-cloudtrail"
  cloudtrail_log_group_name       = var.cloudtrail_log_group_name != null ? var.cloudtrail_log_group_name : "/aws/cloudtrail/${var.resource_prefix}-log-group"
  cloudtrail_iam_role_name        = var.cloudtrail_iam_role_name != null ? var.cloudtrail_iam_role_name : "${var.resource_prefix}-cloudtrail-to-cloudwatch"
  packer_iam_role_name            = var.packer_iam_role_name != null ? var.packer_iam_role_name : "${var.resource_prefix}_packer_role"
  packer_iam_policy_name          = var.packer_iam_policy_name != null ? var.packer_iam_policy_name : "${var.resource_prefix}_packer_policy"
  packer_iam_instanceprofile_name = var.packer_iam_instanceprofile_name != null ? var.packer_iam_instanceprofile_name : "${var.resource_prefix}_packer_profile"
  packer_s3_kmsgrant_name         = var.packer_s3_kmsgrant_name != null ? var.packer_s3_kmsgrant_name : "packer_${var.resource_prefix}_${var.aws_region}_s3_access"
  packer_ebs_kmsgrant_name        = var.packer_ebs_kmsgrant_name != null ? var.packer_ebs_kmsgrant_name : "packer_${var.resource_prefix}_${var.aws_region}_ebs_access"
}
