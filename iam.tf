data "aws_iam_policy" "autoScalePolicy" {
  name = "AutoScalingServiceRolePolicy"
}

# Create the IAM role for Auto Scaling
resource "aws_iam_role" "auto_scaling_role" {
  name = "AWSServiceRoleForAutoScaling"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "autoscaling.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_autoscale_policy" {
  role       = aws_iam_role.auto_scaling_role.name
  policy_arn = data.aws_iam_policy.autoScalePolicy.arn
}