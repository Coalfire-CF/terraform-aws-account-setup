resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  provider   = aws.pak-testing  #Replace "pak-testing" with proper provider name
  key_name   = "prefix-fedramp-mgmt-gov-key" #replace prefix with proper name
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Store the private key in AWS Secrets Manager
resource "aws_secretsmanager_secret" "keypair_secret" {
  provider   = aws.pak-testing  #Replace "pak-testing" with proper provider name
  name       = "/management/fedramp-mgmt-gov/prefix-ec2-key-pair" #replace with proper prefix
  kms_key_id = module.setup.sm_kms_key_id
}

resource "aws_secretsmanager_secret_version" "keypair_secret_version" {
  provider      = aws.pak-testing  #Replace "pak-testing" with proper provider name
  secret_id     = aws_secretsmanager_secret.keypair_secret.id
  secret_string = tls_private_key.ssh_key.private_key_pem
}