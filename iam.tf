
data "aws_iam_policy_document" "packer_assume_role_policy_document" {
  statement {
    sid    = "PackerAssumeRole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "AWS"
      identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${var.account_number}:root"
        ]
    }
  }
  statement {
    sid    = "PackerEC2AssumeRole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "packer_role" {
  name = "packer_role"

  assume_role_policy = data.aws_iam_policy_document.packer_assume_role_policy_document.json
}

data "aws_iam_policy_document" "packer_policy_document" {
  statement {
    sid    = "PackerEC2Perms"
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CopyImage",
      "ec2:CreateImage",
      "ec2:CreateKeypair",
      "ec2:CreateSecurityGroup",
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DeleteKeyPair",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteSnapshot",
      "ec2:DeleteVolume",
      "ec2:DeregisterImage",
      "ec2:DescribeImageAttribute",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeRegions",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DetachVolume",
      "ec2:GetPasswordData",
      "ec2:ModifyImageAttribute",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifySnapshotAttribute",
      "ec2:RegisterImage",
      "ec2:RunInstances",
      "ec2:StopInstances",
      "ec2:TerminateInstances"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "IAMPerms"
    effect = "Allow"
    actions = [
      "iam:PassRole",
      "ec2:AssociateIamInstanceProfile",
      "ec2:ReplaceIamInstanceProfileAssociation",
      "iam:GetInstanceProfile"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "ListObjectsInBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      "${module.s3-installs.arn}",
      "${module.s3-installs.arn}/*"
    ]
  }
  statement {
    sid    = "PackerSSMParameterStore"
    effect = "Allow"
    actions = [
      "ssm:GetParameterHistory",
      "ssm:GetParametersByPath",
      "ssm:GetParameters",
      "ssm:GetParameter",
      "ssm:DescribeParameters",
      "ssm:ListTagsForResource"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:ssm:${var.aws_region}:${var.account_number}:parameter/production/packer/*",
      "arn:${data.aws_partition.current.partition}:ssm:${var.aws_region}:${var.account_number}:parameter/production/ca_secrets_path",
      "arn:${data.aws_partition.current.partition}:ssm:${var.aws_region}:${var.account_number}:parameter/production/siem",
      "arn:${data.aws_partition.current.partition}:ssm:${var.aws_region}:${var.account_number}:parameter/production/mgmt/ca/rootca/root_ca_pub.pem"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid    = "PackerEBSEncrypt"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants"
    ]
    resources = [
      "*"
    ]
  }
}


resource "aws_iam_policy" "packer_policy" {
  name        = "packer_policy"
  description = "General Policy which will attach to ec2 for packer to give access to ec2,s3"
  policy      = data.aws_iam_policy_document.packer_policy_document.json
}

resource "aws_iam_policy_attachment" "packer_access_attach_policy" {
  name       = "packer access attach policy"
  roles      = [aws_iam_role.packer_role.name]
  policy_arn = aws_iam_policy.packer_policy.arn
}

resource "aws_iam_instance_profile" "packer_profile" {
  name = "packer_profile"
  role = aws_iam_role.packer_role.name
}

resource "aws_kms_grant" "packer_s3" {
  name              = "packer-${var.aws_region}-s3-access"
  key_id            = module.security-core.s3_key_id
  grantee_principal = aws_iam_role.packer_role.arn
  operations = [
    "Encrypt",
    "Decrypt",
  "DescribeKey"]
}
resource "aws_kms_grant" "packer_ebs" {
  name              = "packer-${var.aws_region}-ebs-access"
  key_id            = module.ebs_kms_key[0].kms_key_id
  grantee_principal = aws_iam_role.packer_role.arn
  operations = [
    "Encrypt",
    "Decrypt",
  "DescribeKey"]
}