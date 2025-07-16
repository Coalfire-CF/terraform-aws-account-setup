resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name = "${var.resource_prefix}-fedramp-mgmt-gov-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Store the private key in AWS Secrets Manager
resource "aws_secretsmanager_secret" "keypair_secret" {
  name       = "/management/fedramp-mgmt-gov/${var.resource_prefix}-ec2-key-pair"

  kms_key_id = module.setup.sm_kms_key_id
}

resource "aws_secretsmanager_secret_version" "keypair_secret_version" {
  secret_id     = aws_secretsmanager_secret.keypair_secret.id
  secret_string = tls_private_key.ssh_key.private_key_pem
}