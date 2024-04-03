
resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  count             = var.create_cloudtrail ? 1 : 0
  name              = "${var.resource_prefix}-log-group"
  kms_key_id        = module.cloudwatch_kms_key[0].kms_key_arn
  retention_in_days = 30

  tags = {
    Owner = var.resource_prefix
  }
}

resource "aws_iam_role" "cloudtrail-role" {
  count = var.create_cloudtrail ? 1 : 0
  name  = "cloudtrail-to-cloudwatch"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
        },
    "Effect": "Allow",
    "Sid": ""
  }
]
}
EOF
}

resource "aws_iam_policy" "cloudtrail-to-cloudwatch" {
  count       = var.create_cloudtrail ? 1 : 0
  name        = "cloudtrail-to-cloudwatch"
  description = "Policy to allow cloudtrail to send logs to cloudwatch"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailCreateLogStream2014110",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream"
      ],
      "Resource": [
        "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${var.account_number}:log-group:${var.resource_prefix}-log-group:log-stream:${var.account_number}_CloudTrail_${var.aws_region}"
      ]
    },
    {
      "Sid": "AWSCloudTrailPutLogEvents20141101",
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:${data.aws_partition.current.partition}:logs:${var.default_aws_region}:${var.account_number}:log-group:${var.resource_prefix}-log-group:log-stream:${var.account_number}_CloudTrail_${var.aws_region}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "cloudtrail-to-cloudwatch" {
  count      = var.create_cloudtrail ? 1 : 0
  name       = "cloudtrail to cloudwatch access attach policy"
  roles      = [aws_iam_role.cloudtrail-role[0].name]
  policy_arn = aws_iam_policy.cloudtrail-to-cloudwatch[0].arn
}


resource "aws_cloudtrail" "all_cloudtrail" {
  count                         = var.create_cloudtrail ? 1 : 0
  name                          = "${var.resource_prefix}-cloudtrail"
  s3_bucket_name                = module.s3-cloudtrail[0].id
  s3_key_prefix                 = "${var.resource_prefix}-cloudtrail"
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail_log_group[0].arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail-role[0].arn
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  kms_key_id = module.security-core.s3_key_arn
  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket_policy]
}
