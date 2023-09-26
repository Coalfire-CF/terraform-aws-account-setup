<div align="center">
<img src="coalfire_logo.png" width="200">

</div>

# AWS Account Setup Terraform Module


## Description

The AWS account set up module creates the initial account configuration for your project, including IAM roles, KMS keys, S3 installs bucket, and more.

FedRAMP Compliance: High

## Resource List

Resources that are created as a part of this module include:

- IAM roles
- IAM policies
- IAM instance profiles
- KMS keys
- S3 buckets
- Security core module resources

## Usage
```
module "account-setup" {
  source = "github.com/Coalfire-CF/terraform-aws-account-setup"

  aws_region = "us-east-1"
  default_aws_region = "us-east-1"

  application_account_numbers = ["account-number1", "account-number2", "account-number3"]
  account_number = "your-account-number"

  resource_prefix = "pre"
  create_cloudtrail = true
  partition = "aws"
  ad_secrets_manager_path = "your/ad/path"
  enable_aws_config = true
  delete_after = 90
}

```

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_additional_kms_keys"></a> [additional\_kms\_keys](#module\_additional\_kms\_keys) | github.com/Coalfire-CF/ACE-AWS-KMS | n/a |
| <a name="module_backup_kms_key"></a> [backup\_kms\_key](#module\_backup\_kms\_key) | github.com/Coalfire-CF/ACE-AWS-KMS | n/a |
| <a name="module_ebs_kms_key"></a> [ebs\_kms\_key](#module\_ebs\_kms\_key) | github.com/Coalfire-CF/ACE-AWS-KMS | n/a |
| <a name="module_lambda_kms_key"></a> [lambda\_kms\_key](#module\_lambda\_kms\_key) | github.com/Coalfire-CF/ACE-AWS-KMS | n/a |
| <a name="module_rds_kms_key"></a> [rds\_kms\_key](#module\_rds\_kms\_key) | github.com/Coalfire-CF/ACE-AWS-KMS | n/a |
| <a name="module_s3-accesslogs"></a> [s3-accesslogs](#module\_s3-accesslogs) | github.com/Coalfire-CF/ACE-AWS-S3 | n/a |
| <a name="module_s3-backups"></a> [s3-backups](#module\_s3-backups) | github.com/Coalfire-CF/ACE-AWS-S3 | n/a |
| <a name="module_s3-installs"></a> [s3-installs](#module\_s3-installs) | github.com/Coalfire-CF/ACE-AWS-S3 | n/a |
| <a name="module_security-core"></a> [security-core](#module\_security-core) | github.com/Coalfire-CF/ACE-AWS-SecurityCore | n/a |
| <a name="module_sm_kms_key"></a> [sm\_kms\_key](#module\_sm\_kms\_key) | github.com/Coalfire-CF/ACE-AWS-KMS | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.packer_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.packer_attach_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy_attachment.packer_access_attach_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_role.packer_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_kms_grant.packer_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_grant) | resource |
| [aws_iam_policy_document.ebs_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.secrets_manager_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_number"></a> [account\_number](#input\_account\_number) | The AWS account number resources are being deployed into | `string` | n/a | yes |
| <a name="input_application_account_numbers"></a> [application\_account\_numbers](#input\_application\_account\_numbers) | AWS account numbers for all application accounts | `list(string)` | n/a | yes |
| <a name="input_aws_backup_plan_name"></a> [aws\_backup\_plan\_name](#input\_aws\_backup\_plan\_name) | AWS Backup plan name | `string` | `"fedramp-aws-backup-plan"` | no |
| <a name="input_aws_lb_account_ids"></a> [aws\_lb\_account\_ids](#input\_aws\_lb\_account\_ids) | https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html | `map(string)` | <pre>{<br>  "us-east-1": "127311923021",<br>  "us-east-2": "033677994240",<br>  "us-gov-east-1": "190560391635",<br>  "us-gov-west-1": "048591011584",<br>  "us-west-2": "797873946194"<br>}</pre> | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region to create resources in | `string` | n/a | yes |
| <a name="input_backup_rule_name"></a> [backup\_rule\_name](#input\_backup\_rule\_name) | AWS Backup rule name | `string` | `"fedramp-aws-backup-default-rule"` | no |
| <a name="input_backup_selection_tag_value"></a> [backup\_selection\_tag\_value](#input\_backup\_selection\_tag\_value) | AWS Backup tag values | `string` | `"fedramp-daily-aws-backups"` | no |
| <a name="input_backup_vault_name"></a> [backup\_vault\_name](#input\_backup\_vault\_name) | AWS Backup vault name | `string` | `"fedramp-aws-backup-vault"` | no |
| <a name="input_config_delivery_frequency"></a> [config\_delivery\_frequency](#input\_config\_delivery\_frequency) | AWS Config delivery frequencies | `string` | `"One_Hour"` | no |
| <a name="input_create_backup_kms_key"></a> [create\_backup\_kms\_key](#input\_create\_backup\_kms\_key) | create KMS key for AWS Backups | `bool` | `true` | no |
| <a name="input_create_cloudtrail"></a> [create\_cloudtrail](#input\_create\_cloudtrail) | Whether or not to create cloudtrail resources | `bool` | n/a | yes |
| <a name="input_create_dynamo_kms_key"></a> [create\_dynamo\_kms\_key](#input\_create\_dynamo\_kms\_key) | create KMS key for dynamodb | `bool` | `true` | no |
| <a name="input_create_ebs_kms_key"></a> [create\_ebs\_kms\_key](#input\_create\_ebs\_kms\_key) | create KMS key for ebs | `bool` | `true` | no |
| <a name="input_create_lambda_kms_key"></a> [create\_lambda\_kms\_key](#input\_create\_lambda\_kms\_key) | create KMS key for lambda | `bool` | `true` | no |
| <a name="input_create_rds_kms_key"></a> [create\_rds\_kms\_key](#input\_create\_rds\_kms\_key) | create KMS key for rds | `bool` | `true` | no |
| <a name="input_create_s3_kms_key"></a> [create\_s3\_kms\_key](#input\_create\_s3\_kms\_key) | create KMS key for S3 | `bool` | `true` | no |
| <a name="input_create_sm_kms_key"></a> [create\_sm\_kms\_key](#input\_create\_sm\_kms\_key) | create KMS key for secrets manager | `bool` | `true` | no |
| <a name="input_default_aws_region"></a> [default\_aws\_region](#input\_default\_aws\_region) | The default AWS region to create resources in | `string` | n/a | yes |
| <a name="input_delete_after"></a> [delete\_after](#input\_delete\_after) | Number of days after which a recovery point should be deleted | `number` | n/a | yes |
| <a name="input_enable_aws_config"></a> [enable\_aws\_config](#input\_enable\_aws\_config) | Enable AWS config for this account | `bool` | n/a | yes |
| <a name="input_kms_keys"></a> [kms\_keys](#input\_kms\_keys) | a list of maps of KMS keys needed to be created | `list(map(string))` | `null` | no |
| <a name="input_lambda_time_zone"></a> [lambda\_time\_zone](#input\_lambda\_time\_zone) | The time zone for lambda functions | `string` | `"US/Eastern"` | no |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | The prefix for the s3 bucket names | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_additional_kms_key_arns"></a> [additional\_kms\_key\_arns](#output\_additional\_kms\_key\_arns) | n/a |
| <a name="output_additional_kms_key_ids"></a> [additional\_kms\_key\_ids](#output\_additional\_kms\_key\_ids) | n/a |
| <a name="output_backup_kms_key_arn"></a> [backup\_kms\_key\_arn](#output\_backup\_kms\_key\_arn) | n/a |
| <a name="output_backup_kms_key_id"></a> [backup\_kms\_key\_id](#output\_backup\_kms\_key\_id) | n/a |
| <a name="output_ebs_kms_key_arn"></a> [ebs\_kms\_key\_arn](#output\_ebs\_kms\_key\_arn) | n/a |
| <a name="output_ebs_kms_key_id"></a> [ebs\_kms\_key\_id](#output\_ebs\_kms\_key\_id) | n/a |
| <a name="output_lambda_kms_key_arn"></a> [lambda\_kms\_key\_arn](#output\_lambda\_kms\_key\_arn) | n/a |
| <a name="output_lambda_kms_key_id"></a> [lambda\_kms\_key\_id](#output\_lambda\_kms\_key\_id) | n/a |
| <a name="output_rds_kms_key_arn"></a> [rds\_kms\_key\_arn](#output\_rds\_kms\_key\_arn) | n/a |
| <a name="output_rds_kms_key_id"></a> [rds\_kms\_key\_id](#output\_rds\_kms\_key\_id) | n/a |
| <a name="output_s3_access_logs_arn"></a> [s3\_access\_logs\_arn](#output\_s3\_access\_logs\_arn) | n/a |
| <a name="output_s3_access_logs_id"></a> [s3\_access\_logs\_id](#output\_s3\_access\_logs\_id) | n/a |
| <a name="output_s3_backups_arn"></a> [s3\_backups\_arn](#output\_s3\_backups\_arn) | n/a |
| <a name="output_s3_backups_id"></a> [s3\_backups\_id](#output\_s3\_backups\_id) | n/a |
| <a name="output_s3_installs_arn"></a> [s3\_installs\_arn](#output\_s3\_installs\_arn) | n/a |
| <a name="output_s3_installs_id"></a> [s3\_installs\_id](#output\_s3\_installs\_id) | n/a |
| <a name="output_sm_kms_key_arn"></a> [sm\_kms\_key\_arn](#output\_sm\_kms\_key\_arn) | n/a |
| <a name="output_sm_kms_key_id"></a> [sm\_kms\_key\_id](#output\_sm\_kms\_key\_id) | n/a |
<!-- END_TF_DOCS -->

## Contributing

[Relative or absolute link to contributing.md](CONTRIBUTING.md)


## License

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/license/mit/)


## Coalfire Pages

[Absolute link to any relevant Coalfire Pages](https://coalfire.com/)

### Copyright

Copyright © 2023 Coalfire Systems Inc.
