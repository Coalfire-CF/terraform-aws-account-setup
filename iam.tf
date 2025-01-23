resource "aws_iam_service_linked_role" "autoscale" {
  aws_service_name = "autoscaling.amazonaws.com"
}