resource "aws_cloudtrail" "all_cloudtrail" {
  count                         = var.create_cloudtrail ? 1 : 0
  name                          = "${var.resource_prefix}-cloudtrail"
  s3_bucket_name                = module.s3-cloudtrail[0].id
  s3_key_prefix                 = "${var.resource_prefix}-cloudtrail"
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  kms_key_id = module.security-core.s3_key_arn
  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket_policy]
}

module "cloudtrail_event" {
  count                         = var.create_cloudtrail ? 1 : 0

  source    = "./modules/aws-sqss3event"
  partition = data.aws_partition.current.partition
  s3_arn    = module.s3-cloudtrail[0].arn
  s3_name   = module.s3-cloudtrail[0].id
}