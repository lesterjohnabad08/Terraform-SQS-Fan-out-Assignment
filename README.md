# Terraform-SQS-Fan-out-Assignment

## Tasks:
We have used CDK to build a serverless application in class, and knew SQS fan-out
pattern is useful in constructing parallel applications. In this assignment, you need
to implement the following design using either CDK or Terraform.

## Required components:
1. An S3 bucket where users can upload pictures.
2. An S3 bucket to store outputs from the functions. NOTE: Don’t send outputs back to the input bucket. You may get a huge bill if you do so.
3. After uploading a picture, the S3 bucket posts an event to an SNS topic.
4. The SNS topic will push the S3 event to its subscribers. In this assignment, the subscribers are SQS queues.
5. Each SQS queue has a Lambda trigger, which processes messages in the queue. One SQS queue and one Lambda function are required. This GitHub
repository https://github.com/rclc/CreateThumbnail-Lambda-Python-Pillow has an example of generating thumbnail.

## References used to finish this project:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription
https://registry.terraform.io/providers/-/aws/latest/docs/resources/lambda_function
https://registry.terraform.io/providers/-/aws/latest/docs/resources/iam_role
https://registry.terraform.io/providers/-/aws/6.27.0/docs/resources/sqs_queue
https://registry.terraform.io/providers/-/aws/6.27.0/docs/resources/sqs_queue_policy
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function.html
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping

