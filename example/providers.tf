provider "aws" {
  region                 = var.aws_region
  skip_region_validation = true
  use_fips_endpoint      = true
  alias                  = "mgmt"

  assume_role {
    role_arn = "arn:${local.partition}:iam::${local.mgmt_plane_account_id}:role/OrganizationAccountAccessRole"
  }

  default_tags {
    tags = {
      Application = "management-plane"
      Owner       = "Coalfire"
      Team        = "Cloud Services"
      Environment = "prod"
    }
  }
}