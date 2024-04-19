output "event_sqs_arn" {
  value       = aws_sqs_queue.s3_queue.arn
  description = "The arn of the cloudtrail sqs"
}