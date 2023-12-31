output "s3_access_logs_arn" {
  value = module.s3-accesslogs.arn
}

output "s3_elb_access_logs_arn" {
  value = module.s3-elb-accesslogs.arn
}

output "s3_backups_arn" {
  value = module.s3-backups.arn
}

output "s3_installs_arn" {
  value = module.s3-installs.arn
}

output "s3_access_logs_id" {
  value = module.s3-accesslogs.id
}

output "s3_elb_access_logs_id" {
  value = module.s3-elb-accesslogs.id
}

output "s3_backups_id" {
  value = module.s3-backups.id
}

output "s3_installs_id" {
  value = module.s3-installs.id
}

output "s3_kms_key_arn" {
  value = module.security-core.s3_key_arn
}

output "s3_kms_key_id" {
  value = module.security-core.s3_key_id
}

output "dynamo_kms_key_arn" {
  value = module.security-core.dynamo_key_arn
}

output "dynamo_kms_key_id" {
  value = module.security-core.dynamo_key_id
}

output "ebs_kms_key_arn" {
  value = module.ebs_kms_key.*.kms_key_arn
}

output "ebs_kms_key_id" {
  value = module.ebs_kms_key.*.kms_key_id
}

output "sm_kms_key_arn" {
  value = module.sm_kms_key.*.kms_key_arn
}

output "sm_kms_key_id" {
  value = module.sm_kms_key.*.kms_key_id
}

output "backup_kms_key_arn" {
  value = module.backup_kms_key.*.kms_key_arn
}

output "backup_kms_key_id" {
  value = module.backup_kms_key.*.kms_key_id
}

output "lambda_kms_key_arn" {
  value = module.lambda_kms_key.*.kms_key_arn
}

output "lambda_kms_key_id" {
  value = module.lambda_kms_key.*.kms_key_id
}

output "rds_kms_key_arn" {
  value = module.rds_kms_key.*.kms_key_arn
}

output "rds_kms_key_id" {
  value = module.rds_kms_key.*.kms_key_id
}


output "cloudwatch_kms_key_arn" {
  value = module.cloudwatch_kms_key.*.kms_key_arn
}

output "cloudwatch_kms_key_id" {
  value = module.cloudwatch_kms_key.*.kms_key_id
}

output "additional_kms_key_arns" {
  value = module.additional_kms_keys
}

output "additional_kms_key_ids" {
  value = module.additional_kms_keys
}

output "s3_tstate_bucket_name" {
  value = module.security-core.tstate_bucket_name
}

output "dynamodb_table_name" {
  value = module.security-core.dynamodb_table_name
}
