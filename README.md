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
|-- iam.tf
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
