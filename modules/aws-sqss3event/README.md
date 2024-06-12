# aws-sqss3event

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket_notification.bucket_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_sqs_queue.s3_queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.sqs_deadletter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_partition"></a> [partition](#input\_partition) | For East/west use aws or for gov cloud use aws-us-gov | `string` | n/a | yes |
| <a name="input_s3_arn"></a> [s3\_arn](#input\_s3\_arn) | S3 ARN for turing on event notification | `string` | n/a | yes |
| <a name="input_s3_name"></a> [s3\_name](#input\_s3\_name) | S3 name to match queue name | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_event_sqs_arn"></a> [event\_sqs\_arn](#output\_event\_sqs\_arn) | The arn of the cloudtrail sqs |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
