resource "aws_sqs_queue" "s3_queue" {
  name   = "${var.s3_name}-event-notification-queue"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "arn:${var.partition}:sqs:*:*:${var.s3_name}-event-notification-queue",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${var.s3_arn}" }
      }
    }
  ]
}
POLICY

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.sqs_deadletter.arn
    maxReceiveCount     = 4
  })

}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.s3_name
  queue {
    queue_arn = aws_sqs_queue.s3_queue.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

resource "aws_sqs_queue" "sqs_deadletter" {
  name = "${var.s3_name}-deadletter"
  #kms_master_key_id = aws_kms_key.sqs_key.id
}