
resource "aws_iam_role" "packer_role" {
  name = "packer_role"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ec2.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }

 ]
}
EOF
}

resource "aws_iam_policy" "packer_attach_policy" {
  name        = "packer_attach_policy"
  description = "General Policy which will attach to ec2 for packer to give access to desc ec2,s3"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ListObjectsInBucket",
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": ["${aws_s3_bucket.install_bucket.arn}"]
        },
        {
            "Sid": "ReadObjectActions",
            "Effect": "Allow",
            "Action": ["s3:ListBucket","s3:GetObject"],
            "Resource": ["${aws_s3_bucket.install_bucket.arn}/*"]
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "packer_access_attach_policy" {
  name       = "ec2 access attach policy MA"
  roles      = [aws_iam_role.packer_role.name]
  policy_arn = aws_iam_policy.packer_attach_policy.arn
}

resource "aws_iam_instance_profile" "packer_profile" {
  name = "packer_profile"
  role = aws_iam_role.packer_role.name
}

resource "aws_kms_grant" "packer_s3" {
  name              = "packer-${var.aws_region}-s3-access"
  key_id            = module.s3_kms_key.kms_key_id
  grantee_principal = aws_iam_role.packer_role.arn
  operations = [
    "Encrypt",
    "Decrypt",
  "DescribeKey"]
}