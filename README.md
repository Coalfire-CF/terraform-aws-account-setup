<div align="center">
<img src="coalfire_logo.png" width="200">

</div>

## ACE-AWS-Account

Include the name of the Repository as the header above e.g. `ACE-Cloud-Service`

## Dependencies

List any dependencies here. E.g. security-core, region-setup

## Resource List

Insert a high-level list of resources created as a part of this module. E.g.

- IAM roles
- S3 buckets for account specific functions
- AWS config recorder, aggregator and delivery channel 
- AWS backup
- KMS keys
- 

## Code Updates

If applicable, add here. For example, updating variables, updating `tstate.tf`, or remote data sources.

`tstate.tf` Update to the appropriate version and storage accounts, see sample

``` hcl
terraform {
  required_version = ">= 1.1.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.45.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "prod-mp-core-rg"
    storage_account_name = "prodmpsatfstate"
    container_name       = "tfstatecontainer"
    environment          = "usgovernment"
    key                  = "ad.tfstate"
  }
}
```

Change directory to the `active-directory` folder

Run `terraform init` to download modules and create initial local state file.

Run `terraform plan` to ensure no errors and validate plan is deploying expected resources.

Run `terraform apply` to deploy infrastructure.

Update the `remote-data.tf` file to add the security state key

``` hcl

data "terraform_remote_state" "usgv-ad" {
  backend = "azurerm"
  config = {
    storage_account_name = "${local.storage_name_prefix}satfstate"
    resource_group_name  = "${local.resource_prefix}-core-rg"
    container_name       = "${var.location_abbreviation}${var.app_abbreviation}tfstatecontainer"
    environment          = var.az_environment
    key                  = "${var.location_abbreviation}-ad.tfstate"
  }
}
```

## Deployment Steps

This module can be called as outlined below.

- Change directories to the `reponame` directory.
- From the `terraform/azure/reponame` directory run `terraform init`.
- Run `terraform plan` to review the resources being created.
- If everything looks correct in the plan output, run `terraform apply`.

## Usage

Include example for how to call the module below with generic variables

```hcl
provider "azurerm" {
  features {}
}

module "core_sa" {
  source                    = "github.com/Coalfire-CF/ACE-Azure-StorageAccount?ref=vX.X.X"
  name                       = "${replace(var.resource_prefix, "-", "")}tfstatesa"
  resource_group_name        = azurerm_resource_group.management.name
  location                   = var.location
  account_kind               = "StorageV2"
  ip_rules                   = var.ip_for_remote_access
  diag_log_analytics_id      = azurerm_log_analytics_workspace.core-la.id
  virtual_network_subnet_ids = var.fw_virtual_network_subnet_ids
  tags                       = var.tags

  #OPTIONAL
  public_network_access_enabled = true
  enable_customer_managed_key   = true
  cmk_key_vault_id              = module.core_kv.id
  cmk_key_vault_key_name        = azurerm_key_vault_key.tfstate-cmk.name
  storage_containers = [
    "tfstate"
  ]
  storage_shares = [
    {
      name = "test"
      quota = 500
    }
  ]
  lifecycle_policies = [
    {
      prefix_match = ["tfstate"]
      version = {
        delete_after_days_since_creation = 90
      }
    }
  ]
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
| <a name="module_additional_kms_keys"></a> [additional\_kms\_keys](#module\_additional\_kms\_keys) | github.com/Coalfire-CF/ACE-AWS-KMS | draftv0.0.2 |
| <a name="module_backup_kms_key"></a> [backup\_kms\_key](#module\_backup\_kms\_key) | github.com/Coalfire-CF/ACE-AWS-KMS | draftv0.0.2 |
| <a name="module_backups"></a> [backups](#module\_backups) | github.com/Coalfire-CF/ACE-AWS-Backup | draft |
| <a name="module_config"></a> [config](#module\_config) | github.com/Coalfire-CF/ACE-AWS-Config | v0.0.4 |
| <a name="module_ebs_kms_key"></a> [ebs\_kms\_key](#module\_ebs\_kms\_key) | github.com/Coalfire-CF/ACE-AWS-KMS | draftv0.0.2 |
| <a name="module_lambda_kms_key"></a> [lambda\_kms\_key](#module\_lambda\_kms\_key) | github.com/Coalfire-CF/ACE-AWS-KMS | draftv0.0.2 |
| <a name="module_rds_kms_key"></a> [rds\_kms\_key](#module\_rds\_kms\_key) | github.com/Coalfire-CF/ACE-AWS-KMS | draftv0.0.2 |
| <a name="module_s3-accesslogs"></a> [s3-accesslogs](#module\_s3-accesslogs) | github.com/Coalfire-CF/ACE-AWS-S3 | draftv0.0.2 |
| <a name="module_s3-backups"></a> [s3-backups](#module\_s3-backups) | github.com/Coalfire-CF/ACE-AWS-S3 | draftv0.0.2 |
| <a name="module_s3-installs"></a> [s3-installs](#module\_s3-installs) | github.com/Coalfire-CF/ACE-AWS-S3 | draftv0.0.2 |
| <a name="module_security-core"></a> [security-core](#module\_security-core) | github.com/Coalfire-CF/ACE-AWS-SecurityCore | draftv0.0.3 |
| <a name="module_sm_kms_key"></a> [sm\_kms\_key](#module\_sm\_kms\_key) | github.com/Coalfire-CF/ACE-AWS-KMS | draftv0.0.2 |

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
| <a name="input_ad_secrets_manager_path"></a> [ad\_secrets\_manager\_path](#input\_ad\_secrets\_manager\_path) | The path to be used for AD users in parameter store | `string` | n/a | yes |
| <a name="input_application_account_numbers"></a> [application\_account\_numbers](#input\_application\_account\_numbers) | AWS account numbers for all application accounts | `list(string)` | n/a | yes |
| <a name="input_aws_backup_plan_name"></a> [aws\_backup\_plan\_name](#input\_aws\_backup\_plan\_name) | AWS Backup plan name | `string` | `"fedramp-aws-backup-plan"` | no |
| <a name="input_aws_lb_account_ids"></a> [aws\_lb\_account\_ids](#input\_aws\_lb\_account\_ids) | https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html | `map` | `{}` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region to create things in | `string` | n/a | yes |
| <a name="input_backup_rule_name"></a> [backup\_rule\_name](#input\_backup\_rule\_name) | AWS Backup rule name | `string` | `"fedramp-aws-backup-default-rule"` | no |
| <a name="input_backup_selection_tag_value"></a> [backup\_selection\_tag\_value](#input\_backup\_selection\_tag\_value) | AWS Backup tag values | `string` | `"fedramp-daily-aws-backups"` | no |
| <a name="input_backup_vault_name"></a> [backup\_vault\_name](#input\_backup\_vault\_name) | AWS Backup vault name | `string` | `"fedramp-aws-backup-vault"` | no |
| <a name="input_config_delivery_frequency"></a> [config\_delivery\_frequency](#input\_config\_delivery\_frequency) | AWS Config delivery frequencies | `string` | `"One_Hour"` | no |
| <a name="input_create_backup_kms_key"></a> [create\_backup\_kms\_key](#input\_create\_backup\_kms\_key) | create KMS key for AWS Backups | `bool` | `true` | no |
| <a name="input_create_cloudtrail"></a> [create\_cloudtrail](#input\_create\_cloudtrail) | Whether or not to create cloudtrail resources | `bool` | n/a | yes |
| <a name="input_create_dynamo_kms_key"></a> [create\_dynamo\_kms\_key](#input\_create\_dynamo\_kms\_key) | create KMS key for dynamodb | `bool` | `true` | no |
| <a name="input_create_ebs_kms_key"></a> [create\_ebs\_kms\_key](#input\_create\_ebs\_kms\_key) | create KMS key for ebs | `bool` | `true` | no |
| <a name="input_create_lambda_kms_key"></a> [create\_lambda\_kms\_key](#input\_create\_lambda\_kms\_key) | create KMS key for lamb da | `bool` | `true` | no |
| <a name="input_create_rds_kms_key"></a> [create\_rds\_kms\_key](#input\_create\_rds\_kms\_key) | create KMS key for rds | `bool` | `true` | no |
| <a name="input_create_s3_kms_key"></a> [create\_s3\_kms\_key](#input\_create\_s3\_kms\_key) | create KMS key for S3 | `bool` | `true` | no |
| <a name="input_create_sm_kms_key"></a> [create\_sm\_kms\_key](#input\_create\_sm\_kms\_key) | create KMS key for secrets manager | `bool` | `true` | no |
| <a name="input_default_aws_region"></a> [default\_aws\_region](#input\_default\_aws\_region) | The default AWS region to create resources in | `string` | n/a | yes |
| <a name="input_delete_after"></a> [delete\_after](#input\_delete\_after) | n/a | `number` | n/a | yes |
| <a name="input_enable_aws_config"></a> [enable\_aws\_config](#input\_enable\_aws\_config) | Enable AWS config for this account | `bool` | n/a | yes |
| <a name="input_is_gov"></a> [is\_gov](#input\_is\_gov) | Whether or not resources will be deployed in a govcloud region | `bool` | n/a | yes |
| <a name="input_kms_keys"></a> [kms\_keys](#input\_kms\_keys) | a list of maps of KMS keys needed to be created | `list(map(string))` | `null` | no |
| <a name="input_lambda_time_zone"></a> [lambda\_time\_zone](#input\_lambda\_time\_zone) | The time zone for the stopinator lambda funciton | `string` | `"US/Eastern"` | no |
| <a name="input_partition"></a> [partition](#input\_partition) | For East/west use aws or for gov cloud use aws-us-gov | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | The prefix for the s3 bucket names | `string` | n/a | yes |
| <a name="input_ssm_parameter_store_ad_users"></a> [ssm\_parameter\_store\_ad\_users](#input\_ssm\_parameter\_store\_ad\_users) | The path to be used for AD users in parameter store | `string` | `"/production/mgmt/ad/users/"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

## Contributing

[Relative or absolute link to contributing.md](CONTRIBUTING.md)


## License

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/license/mit/)


## Coalfire Pages

[Absolute link to any relevant Coalfire Pages](https://coalfire.com/)

### Copyright

Copyright © 2023 Coalfire Systems Inc.
