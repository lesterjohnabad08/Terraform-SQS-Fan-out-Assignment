terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.36.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
}

data "aws_iam_policy_document" "topic" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = ["arn:aws:sns:*:*:New_S3_Obj_Uploaded_Event_Msg"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.sqs_fan_out_bucket_ljabad.arn]
    }
  }
}

#Create SNS Topic
resource "aws_sns_topic" "New_S3_Obj_Uploaded_Event_Msg" {
  name = "New_S3_Obj_Uploaded_Event_Msg"
  policy = data.aws_iam_policy_document.topic.json
}

#create SQS_Queue
resource "aws_sqs_queue" "sqs_fanout_new_s3_obj_event" {
  name                      = "sqs_fanout_new_s3_obj_event"
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 0  
}

resource "aws_sns_topic_subscription" "New_S3_Obj_Uploaded_Event_Msg_Subscription" {
  topic_arn            = aws_sns_topic.New_S3_Obj_Uploaded_Event_Msg.arn
  protocol             = "email"
  endpoint             = var.email_address
}

resource "aws_sns_topic_subscription" "SQS_Queue_Event_Msg_Subscription" {
  topic_arn            = aws_sns_topic.New_S3_Obj_Uploaded_Event_Msg.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.sqs_fanout_new_s3_obj_event.arn
}

resource "aws_s3_bucket" "sqs_fan_out_bucket_ljabad" {
  bucket = "sqs-fan-out-bucket-ljabad"
}

resource "aws_s3_bucket" "sqs_fan_out_bucket_ljabad_resized" {
  bucket = "sqs-fan-out-bucket-ljabad-resized"
}

resource "aws_s3_bucket_notification" "sqs_fan_out_new_s3_obj_msg_ljabad" {
  bucket = aws_s3_bucket.sqs_fan_out_bucket_ljabad.id

  topic {
    topic_arn     = aws_sns_topic.New_S3_Obj_Uploaded_Event_Msg.arn
    events        = ["s3:ObjectCreated:*"]
    
  }
}

#create Lambda_SQS_Role ********
resource "aws_iam_role" "lambda_s3_sqs_allow_role" {
  name = "lambda_s3_sqs_allow_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "Lambda_S3_SQS_Allow_Role"
  }
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role      = aws_iam_role.lambda_s3_sqs_allow_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "sqs_full_access" {
  role      = aws_iam_role.lambda_s3_sqs_allow_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

#Editing this

#resource "aws_lambda_function" "example" {
 # filename      = "${path.module}/lambda.zip"
 # function_name = "example_lambda_function"
 # role          = aws_iam_role.example.arn 
 # handler       = "lambda_function.handler"
 # runtime       = "python3.12"

#}