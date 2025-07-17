![Coalfire](coalfire_logo.png)

# terraform-aws-account-setup

## Description

The AWS account set up module creates the initial account configuration for your project, including IAM roles, KMS keys, S3 installs bucket, and more.

FedRAMP Compliance: High

## Dependencies

- If applicable: AWS Organization (AWS ORG) ID (https://github.com/Coalfire-CF/terraform-aws-organization)

## Resource List

Resources that are created as a part of this module include:

- IAM role, policies, and instance profiles for Packer to assume during AMI creation (optional: one account can build and store Packer AMIs and share them with other accounts).
- KMS keys and typically required IAM permissions for commonly used services (S3, DynamoDB, ELB, RDS, EBS, etc.).
- S3 buckets:
  - ELB Access Logs bucket is optional. With multiple accounts: you can designate one as a centralized logging account and have other accounts send ELB logs to one account's bucket, this is not possible with S3 access logs where the bucket must be in the same account & region).
  - Set 'create_s3_elb_accesslogs_bucket' to 'true' if this is run in an account where you want the logs to be sent.
- Optional: Security core module resources (Terraform state resources should only exist in the AWS Management account and AWS Org Master Payer account).

## Cross-Account Permissions
There are 3 supported deployment configurations regarding IAM cross-account permissions. Sharing principally concerns S3 Buckets (where applicable) and KMS Key permissions.

Sharing based on AWS ORG (Recommended, easier to maintain since permissions are granted via AWS Organization ID instead of individual account IDs):
```hcl
### Sharing ###
  is_organization                        = true # Should be "false" if setting "application_account_numbers"
  organization_id                        = "your-organization-id"
```

Standalone account (No cross-account sharing: Set "is_organization" to "false" (default is "true"), and you can omit "application_account_numbers" and "organization_id"):
```hcl
### Sharing ###
  is_organization                        = false # Should be "false" if setting "application_account_numbers"
```

Sharing is based on a list of AWS Account IDs:
```hcl
### Sharing ###
  application_account_numbers            = ["account-number1", "account-number2", "account-number3"]
  is_organization                        = false # Should be "false" if setting "application_account_numbers"
```

## AWS Backups
AWS Backups are based on the presence of a tag and can be applied to S3 buckets. The configuration depends on "s3_backup_settings" and "s3_backup_policy". **At a minimum, "s3_backup_policy" must be defined in order for the S3 buckets to be tagged**.  "s3_backup_settings" is an optional map variable that lets you enable or disable AWS Backups on individual S3 buckets that this pak creates.  The default value will NOT tag the S3 Access Logs, ELB Access Logs, or Cloudtrail buckets for AWS Backup.  This is an opinionated default that assumes that a SIEM solution will ingest and store these logs, so having a backup is a waste of money.  But if this is not true, then you can individually override this as shown in the example above. Example:

```hcl
### AWS Backup ###
  s3_backup_policy = "aws-backup-${var.resource_prefix}-default-policy"
  s3_backup_settings = {
    accesslogs = {
      enable_backup = true # Normally "false" because we're assuming that a SIEM will ingest and store these logs
    }
    elb-accesslogs = {
      enable_backup = true # Normally "false" because we're assuming that a SIEM will ingest and store these logs
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
      enable_backup = true # Normally "false" because we're assuming that a SIEM will ingest and store these logs
    }
    config = {
      enable_backup = true
    }
  }
```

## Usage
"Management Core" account: Terraform state is stored here, Packer AMIs are built here, is also Management Account for AWS Organizations:
```hcl
module "account-setup" {
  source = "github.com/Coalfire-CF/terraform-aws-account-setup?ref=v0.0.20"

  aws_region         = "us-gov-west-1"
  default_aws_region = "us-gov-west-1"
  account_number     = "your-account-number"

  resource_prefix         = "pak"
  
  ### Cloudtrail ###
  create_cloudtrail                      = true
  cloudwatch_log_group_retention_in_days = 30

  ### KMS ###
  additional_kms_keys = [
    {
      name   = "elasticache"
      policy = "${data.aws_iam_policy_document.elasticache_key_policy.json}"
    }
  ]

  ### Packer ###
  create_packer_iam = true # Packer AMIs will be built and kept on this account and shared with other accounts (share accounts is provided to Packer as a variable at build time)

  ### Terraform ###
  create_security_core = true # Terraform state will be kept on this account

  ### Sharing ###
  is_organization = true # Should be "false" if setting "application_account_numbers"
  organization_id = "your-organization-id"

  ### AWS Backup ###
  s3_backup_policy = "aws-backup-${var.resource_prefix}-default-policy"
}
```
Optional: "Member account". **This code is not intended to be deployed in every account unless there's a clear need for supporting infrastructure**. Does not need Terraform resources (S3 bucket to store state, DynamoDB table for state lock since these will be stored in MGMT account), Packer AMIs will not be built in this account, is not a Management account for AWS Organizations, does not need to share IAM permissions (s3 buckets, KMS keys) to any other account.  The default configuration also creates individually owned Customer KMS Keys.
```hcl
module "account-setup" {
  source = "github.com/Coalfire-CF/terraform-aws-account-setup?ref=v0.0.20"

  aws_region         = "us-gov-west-1"
  default_aws_region = "us-gov-west-1"

  account_number = "your-account-number"

  resource_prefix = "pak"

  ### KMS ###
  additional_kms_keys = [
    {
      name   = "elasticache"
      policy = "${data.aws_iam_policy_document.elasticache_key_policy.json}"
    }
  ]

  ### Sharing ###
  is_organization = false # Should be "false" if setting "application_account_numbers"

  ### AWS Backup ###
  s3_backup_policy = "aws-backup-${var.resource_prefix}-default-policy"
}
```

## Environment Setup

Establish a secure connection to the Management AWS account used for the build:

```hcl
IAM user authentication:

- Download and install the AWS CLI (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Log into the AWS Console and create AWS CLI Credentials (https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)
- Configure the named profile used for the project, such as 'aws configure --profile example-mgmt'

SSO-based authentication (via IAM Identity Center SSO):

- Login to the AWS IAM Identity Center console, select the permission set for MGMT, and select the 'Access Keys' link.
- Choose the 'IAM Identity Center credentials' method to get the SSO Start URL and SSO Region values.
- Run the setup command 'aws configure sso --profile example-mgmt' and follow the prompts.
- Verify you can run AWS commands successfully, for example 'aws s3 ls --profile example-mgmt'.
- Run 'export AWS_PROFILE=example-mgmt' in your terminal to use the specific profile and avoid having to use '--profile' option.
```

## Deployment

1. Navigate to the Terraform project and create a parent directory in the upper level code, for example:

    ```hcl
    ../{CLOUD}/terraform/{REGION}/management-account/example
    ```
   If multi-account management plane:

    ```hcl
    ../{CLOUD}/terraform/{REGION}/{ACCOUNT_TYPE}-mgmt-account/example
    ```

2. Create a properly defined main.tf file via the template found under 'Usage' while adjusting tfvars as needed. Note that many provided variables are outputs from other modules. For 'Member Account' directories make sure to use a Terraform alias use management account credentials/settings to create resources in member account. Example parent directory:

    ```hcl
     ├── Example/
     │   ├── example.auto.tfvars   
     │   ├── main.tf
     │   ├── outputs.tf
     │   ├── providers.tf
     │   ├── required-providers.tf
     │   ├── remote-data.tf
     │   ├── variables.tf 
     │   ├── ...
     ```

   (Optional) Example AWS ORG Member Account 'main.tf' file using alias:
     ```hcl
     module "account-setup" {
     source = "github.com/Coalfire-CF/terraform-aws-account-setup?ref=v0.0.40"
     providers = {
      aws = aws.example-member-account
     }
     ...
     }
     ```

   (Optional) Example AWS ORG Member Account 'providers.tf'. Set your alias to the account specified name ('example-member-account'). Alias should match the provider being used in main.tf file. Example:
     ```hcl
     provider "aws" {
     region                 = var.aws_region
     skip_region_validation = true
     profile                = var.profile
     use_fips_endpoint      = true
     alias                  = "example-member-account"
     assume_role {
     role_arn = "arn:${local.partition}:iam::${local.example_member_account_account_id}:role/OrganizationAccountAccessRole"
     }
     }
     ```

3. Configure Terraform local backend and stage remote backend. For the first run, the entire contents of the 'remote-data.tf' file must be commented out with terraform local added to facilitate local state setup, like below:
   ```hcl
   //terraform {
   //  backend "s3" {
   //    bucket         = "{resource_prefix}-{region}-tf-state"
   //    region         = "{region}"
   //    key            = "{resource_prefix}-{region}-account-setup.tfstate"
   //    encrypt        = true
   //    use_lockfile   = true
   //  }
   //}
   terraform {
   backend "local"{}
   }
   ```
   AWS ORG Member Account: In 'remote-data.tf', set the key to a directory structure in the format show in the example below:
   ```hcl
   //terraform {
   //  backend "s3" {
   //    bucket         = "{resource_prefix}-{region}-tf-state"
   //    region         = "{region}"
   //    key            = "{account_name}/{region}/{resource_prefix}-{region}-account-setup.tfstate"
   //    encrypt        = true
   //    use_lockfile   = true
   //  }
   //}
   terraform {
   backend "local"{}
   }
   ```
4. Initialize the Terraform working directory:
   ```hcl
   terraform init
   ```
   Create an execution plan and verify the resources being created:
   ```hcl
   terraform plan
   ```
   Apply the configuration:
   ```hcl
   terraform apply
   ```

5. After the deployment has succeeded, uncomment the contents of 'remote-state.tf' and remove the terraform local code block.

6. Run 'terraform init -migrate-state' and follow the prompts to migrate the local state file to the appropriate S3 bucket in the management plane.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.10.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_additional_kms_keys"></a> [additional\_kms\_keys](#module\_additional\_kms\_keys) | github.com/Coalfire-CF/terraform-aws-kms | v1.0.1 |
| <a name="module_backup_kms_key"></a> [backup\_kms\_key](#module\_backup\_kms\_key) | github.com/Coalfire-CF/terraform-aws-kms | v1.0.1 |
| <a name="module_cloudwatch_kms_key"></a> [cloudwatch\_kms\_key](#module\_cloudwatch\_kms\_key) | github.com/Coalfire-CF/terraform-aws-kms | v1.0.1 |
| <a name="module_config_kms_key"></a> [config\_kms\_key](#module\_config\_kms\_key) | github.com/Coalfire-CF/terraform-aws-kms | v1.0.1 |
| <a name="module_default_kms_key"></a> [default\_kms\_key](#module\_default\_kms\_key) | github.com/Coalfire-CF/terraform-aws-kms | v1.0.1 |
| <a name="module_ebs_kms_key"></a> [ebs\_kms\_key](#module\_ebs\_kms\_key) | github.com/Coalfire-CF/terraform-aws-kms | v1.0.1 |
| <a name="module_ecr_kms_key"></a> [ecr\_kms\_key](#module\_ecr\_kms\_key) | github.com/Coalfire-CF/ACE-AWS-KMS | v1.0.1 |
| <a name="module_lambda_kms_key"></a> [lambda\_kms\_key](#module\_lambda\_kms\_key) | github.com/Coalfire-CF/terraform-aws-kms | v1.0.1 |
| <a name="module_nfw_kms_key"></a> [nfw\_kms\_key](#module\_nfw\_kms\_key) | github.com/Coalfire-CF/terraform-aws-kms | v1.0.1 |
| <a name="module_rds_kms_key"></a> [rds\_kms\_key](#module\_rds\_kms\_key) | github.com/Coalfire-CF/terraform-aws-kms | v1.0.1 |
| <a name="module_s3-accesslogs"></a> [s3-accesslogs](#module\_s3-accesslogs) | github.com/Coalfire-CF/terraform-aws-s3 | v1.0.4 |
| <a name="module_s3-backups"></a> [s3-backups](#module\_s3-backups) | github.com/Coalfire-CF/terraform-aws-s3 | v1.0.4 |
| <a name="module_s3-cloudtrail"></a> [s3-cloudtrail](#module\_s3-cloudtrail) | github.com/Coalfire-CF/terraform-aws-s3 | v1.0.4 |
| <a name="module_s3-config"></a> [s3-config](#module\_s3-config) | github.com/Coalfire-CF/terraform-aws-s3 | v1.0.4 |
| <a name="module_s3-elb-accesslogs"></a> [s3-elb-accesslogs](#module\_s3-elb-accesslogs) | github.com/Coalfire-CF/terraform-aws-s3 | v1.0.4 |
| <a name="module_s3-fedrampdoc"></a> [s3-fedrampdoc](#module\_s3-fedrampdoc) | github.com/Coalfire-CF/terraform-aws-s3 | v1.0.4 |
| <a name="module_s3-installs"></a> [s3-installs](#module\_s3-installs) | github.com/Coalfire-CF/terraform-aws-s3 | v1.0.4 |
| <a name="module_s3_kms_key"></a> [s3\_kms\_key](#module\_s3\_kms\_key) | github.com/Coalfire-CF/terraform-aws-kms | v1.0.1 |
| <a name="module_security-core"></a> [security-core](#module\_security-core) | github.com/Coalfire-CF/terraform-aws-securitycore | v0.0.24 |
| <a name="module_sm_kms_key"></a> [sm\_kms\_key](#module\_sm\_kms\_key) | github.com/Coalfire-CF/terraform-aws-kms | v1.0.1 |
| <a name="module_sns_kms_key"></a> [sns\_kms\_key](#module\_sns\_kms\_key) | github.com/Coalfire-CF/terraform-aws-kms | v1.0.1 |
| <a name="module_sqs_kms_key"></a> [sqs\_kms\_key](#module\_sqs\_kms\_key) | github.com/Coalfire-CF/ACE-AWS-KMS | v1.0.1 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudtrail.all_cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail) | resource |
| [aws_cloudwatch_log_group.cloudtrail_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_instance_profile.packer_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.cloudtrail-to-cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.packer_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy_attachment.cloudtrail-to-cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_policy_attachment.packer_access_attach_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_role.cloudtrail-role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.packer_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_service_linked_role.autoscale](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_key_pair.generated_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_kms_grant.packer_ebs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_grant) | resource |
| [aws_kms_grant.packer_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_grant) | resource |
| [aws_s3_bucket_policy.cloudtrail_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.config_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_secretsmanager_secret.keypair_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.keypair_secret_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [tls_private_key.ssh_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_elb_service_account.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/elb_service_account) | data source |
| [aws_iam_policy_document.additional_kms_keys](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudtrail_assume_role_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudtrail_to_cloudwatch_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudwatch_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.config_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.default_key_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ebs_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecr_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.elb_accesslogs_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kms_base_and_sharing_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.log_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.packer_assume_role_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.packer_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_accesslogs_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_config_bucket_policy_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.secrets_manager_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sns_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sqs_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_number"></a> [account\_number](#input\_account\_number) | The AWS account number resources are being deployed into | `string` | n/a | yes |
| <a name="input_additional_kms_keys"></a> [additional\_kms\_keys](#input\_additional\_kms\_keys) | a list of maps of any additional KMS keys that need to be created | `list(map(string))` | `[]` | no |
| <a name="input_application_account_numbers"></a> [application\_account\_numbers](#input\_application\_account\_numbers) | AWS account numbers for all application accounts that might need shared access to resources like KMS keys | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region to create resources in | `string` | n/a | yes |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | The number of days to retain Cloudwatch logs | `number` | `30` | no |
| <a name="input_create_autoscale_role"></a> [create\_autoscale\_role](#input\_create\_autoscale\_role) | Create AWS Autoscale IAM Role (needed for any autoscaling aws resources) | `bool` | `true` | no |
| <a name="input_create_backup_kms_key"></a> [create\_backup\_kms\_key](#input\_create\_backup\_kms\_key) | create KMS key for AWS Backups | `bool` | `true` | no |
| <a name="input_create_cloudtrail"></a> [create\_cloudtrail](#input\_create\_cloudtrail) | Whether or not to create cloudtrail resources | `bool` | `false` | no |
| <a name="input_create_cloudwatch_kms_key"></a> [create\_cloudwatch\_kms\_key](#input\_create\_cloudwatch\_kms\_key) | create KMS key for AWS Cloudwatch | `bool` | `true` | no |
| <a name="input_create_config_kms_key"></a> [create\_config\_kms\_key](#input\_create\_config\_kms\_key) | create KMS key for AWS Cloudwatch | `bool` | `true` | no |
| <a name="input_create_default_kms_key"></a> [create\_default\_kms\_key](#input\_create\_default\_kms\_key) | create default kms key | `bool` | `true` | no |
| <a name="input_create_ebs_kms_key"></a> [create\_ebs\_kms\_key](#input\_create\_ebs\_kms\_key) | create KMS key for ebs | `bool` | `true` | no |
| <a name="input_create_ecr_kms_key"></a> [create\_ecr\_kms\_key](#input\_create\_ecr\_kms\_key) | create KMS key for ECR | `bool` | `true` | no |
| <a name="input_create_lambda_kms_key"></a> [create\_lambda\_kms\_key](#input\_create\_lambda\_kms\_key) | create KMS key for lambda | `bool` | `true` | no |
| <a name="input_create_nfw_kms_key"></a> [create\_nfw\_kms\_key](#input\_create\_nfw\_kms\_key) | create KMS key for NFW | `bool` | `true` | no |
| <a name="input_create_packer_iam"></a> [create\_packer\_iam](#input\_create\_packer\_iam) | Whether or not to create Packer IAM resources | `bool` | `false` | no |
| <a name="input_create_rds_kms_key"></a> [create\_rds\_kms\_key](#input\_create\_rds\_kms\_key) | create KMS key for rds | `bool` | `true` | no |
| <a name="input_create_s3_accesslogs_bucket"></a> [create\_s3\_accesslogs\_bucket](#input\_create\_s3\_accesslogs\_bucket) | Create S3 Access Logs Bucket | `bool` | `true` | no |
| <a name="input_create_s3_backups_bucket"></a> [create\_s3\_backups\_bucket](#input\_create\_s3\_backups\_bucket) | Create S3 Backups Bucket | `bool` | `true` | no |
| <a name="input_create_s3_config_bucket"></a> [create\_s3\_config\_bucket](#input\_create\_s3\_config\_bucket) | Create S3 AWS Config Bucket for conformance pack storage | `bool` | `true` | no |
| <a name="input_create_s3_elb_accesslogs_bucket"></a> [create\_s3\_elb\_accesslogs\_bucket](#input\_create\_s3\_elb\_accesslogs\_bucket) | Create S3 ELB Access Logs Bucket | `bool` | `true` | no |
| <a name="input_create_s3_fedrampdoc_bucket"></a> [create\_s3\_fedrampdoc\_bucket](#input\_create\_s3\_fedrampdoc\_bucket) | Create S3 FedRAMP Documents Bucket | `bool` | `true` | no |
| <a name="input_create_s3_installs_bucket"></a> [create\_s3\_installs\_bucket](#input\_create\_s3\_installs\_bucket) | Create S3 Installs Bucket | `bool` | `true` | no |
| <a name="input_create_s3_kms_key"></a> [create\_s3\_kms\_key](#input\_create\_s3\_kms\_key) | create KMS key for S3 | `bool` | `true` | no |
| <a name="input_create_security_core"></a> [create\_security\_core](#input\_create\_security\_core) | Whether or not to create Security Core resources | `bool` | `false` | no |
| <a name="input_create_sm_kms_key"></a> [create\_sm\_kms\_key](#input\_create\_sm\_kms\_key) | create KMS key for secrets manager | `bool` | `true` | no |
| <a name="input_create_sns_kms_key"></a> [create\_sns\_kms\_key](#input\_create\_sns\_kms\_key) | create KMS key for SNS | `bool` | `true` | no |
| <a name="input_create_sqs_kms_key"></a> [create\_sqs\_kms\_key](#input\_create\_sqs\_kms\_key) | create KMS key for SQS | `bool` | `true` | no |
| <a name="input_default_aws_region"></a> [default\_aws\_region](#input\_default\_aws\_region) | The default AWS region to create resources in | `string` | n/a | yes |
| <a name="input_is_organization"></a> [is\_organization](#input\_is\_organization) | Whether or not to enable certain settings for AWS Organization | `bool` | `true` | no |
| <a name="input_kms_multi_region"></a> [kms\_multi\_region](#input\_kms\_multi\_region) | Indicates whether the KMS key is a multi-Region (true) or regional (false) key. | `bool` | `false` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | AWS Organization ID | `string` | `null` | no |
| <a name="input_packer_additional_iam_principal_arns"></a> [packer\_additional\_iam\_principal\_arns](#input\_packer\_additional\_iam\_principal\_arns) | List of IAM Principal ARNs allowed to assume the Packer IAM Role | `list(string)` | `[]` | no |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | The prefix for resources | `string` | n/a | yes |
| <a name="input_s3_backup_policy"></a> [s3\_backup\_policy](#input\_s3\_backup\_policy) | S3 backup policy to use for S3 buckets in conjunction with AWS Backups, should match an existing policy | `string` | `""` | no |
| <a name="input_s3_backup_settings"></a> [s3\_backup\_settings](#input\_s3\_backup\_settings) | Map of S3 bucket types to their backup settings | <pre>map(object({<br/>    enable_backup = bool<br/>  }))</pre> | <pre>{<br/>  "accesslogs": {<br/>    "enable_backup": false<br/>  },<br/>  "backups": {<br/>    "enable_backup": true<br/>  },<br/>  "cloudtrail": {<br/>    "enable_backup": false<br/>  },<br/>  "config": {<br/>    "enable_backup": true<br/>  },<br/>  "elb-accesslogs": {<br/>    "enable_backup": false<br/>  },<br/>  "fedrampdoc": {<br/>    "enable_backup": true<br/>  },<br/>  "installs": {<br/>    "enable_backup": true<br/>  }<br/>}</pre> | no |
| <a name="input_s3_tags"></a> [s3\_tags](#input\_s3\_tags) | Tags to be applied to S3 buckets | `map(any)` | `{}` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | The name of the SSH key pair to use for EC2 instances. | `string` | `"fedramp-mgmt-gov-key"` | no |
| <a name="input_ssh_key_secret_name"></a> [ssh\_key\_secret\_name](#input\_ssh\_key\_secret\_name) | The name of the secret in Secrets Manager that stores the private SSH key. | `string` | `"/management/fedramp-mgmt-gov/ec2-key-pair"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_additional_kms_key_arns"></a> [additional\_kms\_key\_arns](#output\_additional\_kms\_key\_arns) | n/a |
| <a name="output_additional_kms_key_ids"></a> [additional\_kms\_key\_ids](#output\_additional\_kms\_key\_ids) | n/a |
| <a name="output_backup_kms_key_arn"></a> [backup\_kms\_key\_arn](#output\_backup\_kms\_key\_arn) | n/a |
| <a name="output_backup_kms_key_id"></a> [backup\_kms\_key\_id](#output\_backup\_kms\_key\_id) | n/a |
| <a name="output_cloudwatch_kms_key_arn"></a> [cloudwatch\_kms\_key\_arn](#output\_cloudwatch\_kms\_key\_arn) | n/a |
| <a name="output_cloudwatch_kms_key_id"></a> [cloudwatch\_kms\_key\_id](#output\_cloudwatch\_kms\_key\_id) | n/a |
| <a name="output_config_kms_key_arn"></a> [config\_kms\_key\_arn](#output\_config\_kms\_key\_arn) | n/a |
| <a name="output_config_kms_key_id"></a> [config\_kms\_key\_id](#output\_config\_kms\_key\_id) | n/a |
| <a name="output_ebs_kms_key_arn"></a> [ebs\_kms\_key\_arn](#output\_ebs\_kms\_key\_arn) | n/a |
| <a name="output_ebs_kms_key_id"></a> [ebs\_kms\_key\_id](#output\_ebs\_kms\_key\_id) | n/a |
| <a name="output_ecr_kms_key_arn"></a> [ecr\_kms\_key\_arn](#output\_ecr\_kms\_key\_arn) | n/a |
| <a name="output_ecr_kms_key_id"></a> [ecr\_kms\_key\_id](#output\_ecr\_kms\_key\_id) | n/a |
| <a name="output_lambda_kms_key_arn"></a> [lambda\_kms\_key\_arn](#output\_lambda\_kms\_key\_arn) | n/a |
| <a name="output_lambda_kms_key_id"></a> [lambda\_kms\_key\_id](#output\_lambda\_kms\_key\_id) | n/a |
| <a name="output_nfw_kms_key_arn"></a> [nfw\_kms\_key\_arn](#output\_nfw\_kms\_key\_arn) | n/a |
| <a name="output_nfw_kms_key_id"></a> [nfw\_kms\_key\_id](#output\_nfw\_kms\_key\_id) | n/a |
| <a name="output_packer_iam_role_arn"></a> [packer\_iam\_role\_arn](#output\_packer\_iam\_role\_arn) | n/a |
| <a name="output_packer_iam_role_name"></a> [packer\_iam\_role\_name](#output\_packer\_iam\_role\_name) | n/a |
| <a name="output_rds_kms_key_arn"></a> [rds\_kms\_key\_arn](#output\_rds\_kms\_key\_arn) | n/a |
| <a name="output_rds_kms_key_id"></a> [rds\_kms\_key\_id](#output\_rds\_kms\_key\_id) | n/a |
| <a name="output_s3_access_logs_arn"></a> [s3\_access\_logs\_arn](#output\_s3\_access\_logs\_arn) | n/a |
| <a name="output_s3_access_logs_id"></a> [s3\_access\_logs\_id](#output\_s3\_access\_logs\_id) | n/a |
| <a name="output_s3_backups_arn"></a> [s3\_backups\_arn](#output\_s3\_backups\_arn) | n/a |
| <a name="output_s3_backups_id"></a> [s3\_backups\_id](#output\_s3\_backups\_id) | n/a |
| <a name="output_s3_cloudtrail_arn"></a> [s3\_cloudtrail\_arn](#output\_s3\_cloudtrail\_arn) | n/a |
| <a name="output_s3_cloudtrail_id"></a> [s3\_cloudtrail\_id](#output\_s3\_cloudtrail\_id) | n/a |
| <a name="output_s3_config_arn"></a> [s3\_config\_arn](#output\_s3\_config\_arn) | n/a |
| <a name="output_s3_config_id"></a> [s3\_config\_id](#output\_s3\_config\_id) | n/a |
| <a name="output_s3_elb_access_logs_arn"></a> [s3\_elb\_access\_logs\_arn](#output\_s3\_elb\_access\_logs\_arn) | n/a |
| <a name="output_s3_elb_access_logs_id"></a> [s3\_elb\_access\_logs\_id](#output\_s3\_elb\_access\_logs\_id) | n/a |
| <a name="output_s3_fedrampdoc_arn"></a> [s3\_fedrampdoc\_arn](#output\_s3\_fedrampdoc\_arn) | n/a |
| <a name="output_s3_fedrampdoc_id"></a> [s3\_fedrampdoc\_id](#output\_s3\_fedrampdoc\_id) | n/a |
| <a name="output_s3_installs_arn"></a> [s3\_installs\_arn](#output\_s3\_installs\_arn) | n/a |
| <a name="output_s3_installs_id"></a> [s3\_installs\_id](#output\_s3\_installs\_id) | n/a |
| <a name="output_s3_kms_key_arn"></a> [s3\_kms\_key\_arn](#output\_s3\_kms\_key\_arn) | n/a |
| <a name="output_s3_kms_key_id"></a> [s3\_kms\_key\_id](#output\_s3\_kms\_key\_id) | n/a |
| <a name="output_s3_tstate_bucket_name"></a> [s3\_tstate\_bucket\_name](#output\_s3\_tstate\_bucket\_name) | n/a |
| <a name="output_sm_kms_key_arn"></a> [sm\_kms\_key\_arn](#output\_sm\_kms\_key\_arn) | n/a |
| <a name="output_sm_kms_key_id"></a> [sm\_kms\_key\_id](#output\_sm\_kms\_key\_id) | n/a |
| <a name="output_sns_kms_key_arn"></a> [sns\_kms\_key\_arn](#output\_sns\_kms\_key\_arn) | n/a |
| <a name="output_sns_kms_key_id"></a> [sns\_kms\_key\_id](#output\_sns\_kms\_key\_id) | n/a |
| <a name="output_sqs_kms_key_arn"></a> [sqs\_kms\_key\_arn](#output\_sqs\_kms\_key\_arn) | n/a |
| <a name="output_sqs_kms_key_id"></a> [sqs\_kms\_key\_id](#output\_sqs\_kms\_key\_id) | n/a |
<!-- END_TF_DOCS -->

## Contributing

If you're interested in contributing to our projects, please review the [Contributing Guidelines](CONTRIBUTING.md). And send an email to [our team](contributing@coalfire.com) to receive a copy of our CLA and start the onboarding process.

## License

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/license/mit/)

### Copyright

Copyright © 2023 Coalfire Systems Inc.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Tree
```
.
|-- CHANGELOG.md
|-- CONTRIBUTING.md
|-- License.md
|-- README.md
|-- cloudtrail.tf
|-- coalfire_logo.png
|-- data.tf
|-- ec2-key-pair.tf
|-- iam.tf
|-- kms-iam.tf
|-- kms.tf
|-- outputs.tf
|-- packer_iam.tf
|-- providers.tf
|-- release-please-config.json
|-- s3-accesslog.tf
|-- s3-aws-config.tf
|-- s3-backups.tf
|-- s3-cloudtrail.tf
|-- s3-elb-accesslog.tf
|-- s3-fedrampdoc.tf
|-- s3-installs.tf
|-- security-core.tf
|-- update-readme-tree.sh
|-- variables.tf
```
