variable "partition" {
  type        = string
  description = "For East/west use aws or for gov cloud use aws-us-gov"
}

variable "s3_arn" {
  type        = string
  description = "S3 ARN for turing on event notification"
}
variable "s3_name" {
  type        = string
  description = "S3 name to match queue name"
}