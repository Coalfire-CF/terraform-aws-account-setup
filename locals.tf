locals {
  # Default names for resources
  cloudtrail_name           = var.cloudtrail_name != null ? var.cloudtrail_name : "${var.resource_prefix}-cloudtrail"
  cloudtrail_bucket_name    = var.cloudtrail_bucket_name != null ? var.cloudtrail_bucket_name : "${var.resource_prefix}-cloudtrail"
  cloudtrail_log_group_name = var.cloudtrail_log_group_name != null ? var.cloudtrail_log_group_name : "/aws/cloudtrail/${var.resource_prefix}-log-group"
}
