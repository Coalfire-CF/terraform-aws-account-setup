resource "aws_cloudtrail" "all_cloudtrail" {
  count = var.create_cloudtrail ? 1 : 0

  #provider = var.cloudtrail_provider

  name                          = "${var.resource_prefix}-cloudtrail"
  s3_bucket_name                = module.s3-cloudtrail[0].id
  s3_key_prefix                 = "${var.resource_prefix}-cloudtrail"
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail_log_group[0].arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail-role[0].arn
  is_multi_region_trail         = true
  is_organization_trail         = var.is_organization ? true : false
  include_global_service_events = true
  enable_log_file_validation    = true
  kms_key_id                    = module.s3_kms_key[0].kms_key_arn
  depends_on                    = [aws_s3_bucket_policy.cloudtrail_bucket_policy]
}
resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  count = var.create_cloudtrail ? 1 : 0

  #checkov:skip=CKV_AWS_338: "Ensure CloudWatch log groups retains logs for at least 1 year" - Logs are retained on SIEM/Logging Server
  name              = "/aws/cloudtrail/${var.resource_prefix}-log-group"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = module.cloudwatch_kms_key[0].kms_key_arn

  tags = {
    Owner = var.resource_prefix
  }
}
resource "aws_iam_role" "cloudtrail-role" {
  count = var.create_cloudtrail ? 1 : 0

  name = "${var.resource_prefix}-cloudtrail-to-cloudwatch"

  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume_role_policy_document[0].json
}

data "aws_iam_policy_document" "cloudtrail_assume_role_policy_document" {
  count = var.create_cloudtrail ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "cloudtrail-to-cloudwatch" {
  count = var.create_cloudtrail ? 1 : 0

  name        = "${var.resource_prefix}-cloudtrail-to-cloudwatch"
  description = "Policy to allow cloudtrail to send logs to cloudwatch"

  policy = data.aws_iam_policy_document.cloudtrail_to_cloudwatch_policy_document[0].json
}

data "aws_iam_policy_document" "cloudtrail_to_cloudwatch_policy_document" {
  count = var.create_cloudtrail ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream"
    ]
    resources = concat([
      "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${var.account_number}:log-group:/aws/cloudtrail/${var.resource_prefix}-log-group:log-stream:${var.account_number}_CloudTrail_${var.aws_region}*",
      "arn:aws-us-gov:logs:us-gov-west-1:166938737587:log-group:/aws/cloudtrail/odcg-log-group:*"
      ],
      var.is_organization ? [
        "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${var.account_number}:log-group:/aws/cloudtrail/${var.resource_prefix}-log-group:log-stream:${var.organization_id}_*"
      ] : []
    )
  }
}

resource "aws_iam_policy_attachment" "cloudtrail-to-cloudwatch" {
  count = var.create_cloudtrail ? 1 : 0

  name       = "cloudtrail to cloudwatch access attach policy"
  roles      = [aws_iam_role.cloudtrail-role[0].name]
  policy_arn = aws_iam_policy.cloudtrail-to-cloudwatch[0].arn
}
