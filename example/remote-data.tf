terraform {
  backend "s3" {
    bucket       = "client-mgmt-us-gov-west-1-tf-state" # Update accordingly
    region       = "us-gov-west-1"
    key          = "client-mgmt/us-gov-west-1/account-setup.tfstate" # Update accordingly
    encrypt      = true
    use_lockfile = true
  }
}