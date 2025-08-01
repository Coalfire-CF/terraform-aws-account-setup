locals {
  # Default names for resources
  cloudtrail_name = var.cloudtrail_name != null ? var.cloudtrail_name : "${var.resource_prefix}-cloudtrail"
}
