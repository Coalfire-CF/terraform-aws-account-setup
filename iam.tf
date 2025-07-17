resource "aws_iam_service_linked_role" "autoscale" {
  count            = var.create_autoscale_role ? 1 : 0
  aws_service_name = "autoscaling.amazonaws.com"
}