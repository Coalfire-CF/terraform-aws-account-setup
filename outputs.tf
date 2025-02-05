output "s3_access_logs_arn" {
  value = try(module.s3-accesslogs[0].arn, null)
}

output "s3_elb_access_logs_arn" {
  value = try(module.s3-elb-accesslogs[0].arn, null)
}

output "s3_backups_arn" {
  value = try(module.s3-backups[0].arn, null)
}

output "s3_installs_arn" {
  value = try(module.s3-installs[0].arn, null)
}

output "s3_cloudtrail_arn" {
  value = try(module.s3-cloudtrail[0].arn, null)
}

output "s3_fedrampdoc_arn" {
  value = try(module.s3-fedrampdoc[0].arn, null)
}

output "s3_config_arn" {
  value = try(module.s3-config[0].arn, null)
}

output "s3_access_logs_id" {
  value = try(module.s3-accesslogs[0].id, null)
}

output "s3_elb_access_logs_id" {
  value = try(module.s3-elb-accesslogs[0].id, null)
}

output "s3_backups_id" {
  value = try(module.s3-backups[0].id, null)
}

output "s3_installs_id" {
  value = try(module.s3-installs[0].id, null)
}

output "s3_cloudtrail_id" {
  value = try(module.s3-cloudtrail[0].id, null)
}

output "s3_fedrampdoc_id" {
  value = try(module.s3-fedrampdoc[0].id, null)
}

output "s3_config_id" {
  value = try(module.s3-config[0].id, null)
}

output "s3_kms_key_arn" {
  value = try(module.s3_kms_key[0].kms_key_arn, null)
}

output "s3_kms_key_id" {
  value = try(module.s3_kms_key[0].kms_key_id, null)
}

output "dynamo_kms_key_arn" {
  value = try(module.dynamo_kms_key[0].kms_key_arn, null)
}

output "dynamo_kms_key_id" {
  value = try(module.dynamo_kms_key[0].kms_key_id, null)
}

output "ebs_kms_key_arn" {
  value = try(module.ebs_kms_key[0].kms_key_arn, null)
}

output "ebs_kms_key_id" {
  value = try(module.ebs_kms_key[0].kms_key_id, null)
}

output "sm_kms_key_arn" {
  value = try(module.sm_kms_key[0].kms_key_arn, null)
}

output "sm_kms_key_id" {
  value = try(module.sm_kms_key[0].kms_key_id, null)
}

output "backup_kms_key_arn" {
  value = try(module.backup_kms_key[0].kms_key_arn, null)
}

output "backup_kms_key_id" {
  value = try(module.backup_kms_key[0].kms_key_id, null)
}

output "lambda_kms_key_arn" {
  value = try(module.lambda_kms_key[0].kms_key_arn, null)
}

output "lambda_kms_key_id" {
  value = try(module.lambda_kms_key[0].kms_key_id, null)
}

output "rds_kms_key_arn" {
  value = try(module.rds_kms_key[0].kms_key_arn, null)
}

output "rds_kms_key_id" {
  value = try(module.rds_kms_key[0].kms_key_id, null)
}

output "sns_kms_key_id" {
  value = try(module.sns_kms_key[0].kms_key_id, null)
}

output "sns_kms_key_arn" {
  value = try(module.sns_kms_key[0].kms_key_arn, null)
}

output "cloudwatch_kms_key_arn" {
  value = try(module.cloudwatch_kms_key[0].kms_key_arn, null)
}

output "cloudwatch_kms_key_id" {
  value = try(module.cloudwatch_kms_key[0].kms_key_id, null)
}

output "config_kms_key_arn" {
  value = try(module.config_kms_key[0].kms_key_arn, null)
}

output "config_kms_key_id" {
  value = try(module.config_kms_key[0].kms_key_id, null)
}

output "ecr_kms_key_arn" {
  value = try(module.ecr_kms_key[0].kms_key_arn, null)
}

output "ecr_kms_key_id" {
  value = try(module.ecr_kms_key[0].kms_key_id, null)
}

output "additional_kms_key_arns" {
  value = { for k, v in module.additional_kms_keys : k => v.kms_key_arn }
}

output "additional_kms_key_ids" {
  value = { for k, v in module.additional_kms_keys : k => v.kms_key_id }
}

output "s3_tstate_bucket_name" {
  value = try(module.security-core[0].tstate_bucket_name, null)
}

output "dynamodb_table_name" {
  value = try(module.security-core[0].dynamodb_table_name, null)
}

output "packer_iam_role_arn" {
  value = try(aws_iam_role.packer_role[0].arn, null)
}

output "packer_iam_role_name" {
  value = try(aws_iam_role.packer_role[0].name, null)
}
