data "aws_iam_policy_document" "default_key_policy" {
  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html

  statement {
    sid     = "Enable MGMT IAM User Permissions"
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${var.account_number}:root"]
      type        = "AWS"
    }
    resources = ["*"]
  }

  statement {
    sid    = "Allow SQS S3 KMS Key access"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]
    principals {
      identifiers = ["s3.amazonaws.com"]
      type        = "Service"
    }
    resources = ["*"]
  }
}