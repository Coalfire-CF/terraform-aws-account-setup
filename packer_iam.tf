data "aws_iam_policy_document" "packer_assume_role_policy_document" {
  statement {
    sid     = "PackerAssumeRoleAdministrator"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${var.account_number}:root"]
    }
  }

  statement {
    sid     = "PackerEC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }

  dynamic "statement" {
    for_each = var.packer_additional_iam_principal_arns
    content {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals {
        type        = "AWS"
        identifiers = [statement.value]
      }
    }
  }
}

resource "aws_iam_role" "packer_role" {
  count = var.create_packer_iam ? 1 : 0

  name = "${var.resource_prefix}_packer_role"

  assume_role_policy = data.aws_iam_policy_document.packer_assume_role_policy_document.json
}

data "aws_iam_policy_document" "packer_policy_document" {
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_110: "Ensure IAM policies does not allow privilege escalation"
  # Permissions are specified as required by Hashicorp to run Packer
  # https://developer.hashicorp.com/packer/integrations/hashicorp/amazon#iam-task-or-instance-role
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
    sid    = "PackerEC2SpotPerms"
    effect = "Allow"
    actions = [
      "ec2:CreateLaunchTemplate",
      "ec2:DeleteLaunchTemplate",
      "ec2:CreateFleet",
      "ec2:DescribeSpotPriceHistory"
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
      "iam:GetInstanceProfile",
      "iam:CreateServiceLinkedRole"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ListObjectsInBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      module.s3-installs[0].arn,
      "${module.s3-installs[0].arn}/*"
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
    resources = ["*"]
  }
}


resource "aws_iam_policy" "packer_policy" {
  count = var.create_packer_iam ? 1 : 0

  name        = "${var.resource_prefix}_packer_policy"
  description = "General Policy which will attach to ec2 for packer to give access to ec2,s3"
  policy      = data.aws_iam_policy_document.packer_policy_document.json
}

resource "aws_iam_policy_attachment" "packer_access_attach_policy" {
  count = var.create_packer_iam ? 1 : 0

  name       = "packer access attach policy"
  roles      = [aws_iam_role.packer_role[0].name]
  policy_arn = aws_iam_policy.packer_policy[0].arn
}

resource "aws_iam_instance_profile" "packer_profile" {
  count = var.create_packer_iam ? 1 : 0

  name = "${var.resource_prefix}_packer_profile"
  role = aws_iam_role.packer_role[0].name
}

resource "aws_kms_grant" "packer_s3" {
  count = var.create_packer_iam ? 1 : 0

  name              = "packer_${var.resource_prefix}_${var.aws_region}_s3_access"
  key_id            = module.s3_kms_key[0].kms_key_arn
  grantee_principal = aws_iam_role.packer_role[0].arn
  operations = [
    "Encrypt",
    "Decrypt",
    "DescribeKey"
  ]
}
resource "aws_kms_grant" "packer_ebs" {
  count = var.create_packer_iam ? 1 : 0

  name              = "packer_${var.resource_prefix}_${var.aws_region}_ebs_access"
  key_id            = module.ebs_kms_key[0].kms_key_id
  grantee_principal = aws_iam_role.packer_role[0].arn
  operations = [
    "Encrypt",
    "Decrypt",
    "DescribeKey"
  ]
}
