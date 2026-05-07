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

###################
#       Topic     #
###################

#Topic Policy
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
  #attach topic policy
  policy = data.aws_iam_policy_document.topic.json
}

#Uncomment this if email notification is required
/*
#Email Subscription to SNS Topic
resource "aws_sns_topic_subscription" "New_S3_Obj_Uploaded_Event_Msg_Subscription" {
  topic_arn            = aws_sns_topic.New_S3_Obj_Uploaded_Event_Msg.arn
  protocol             = "email"
  endpoint             = var.email_address
}
*/
# Subscribe SQS_Queue to SNS Topic
resource "aws_sns_topic_subscription" "SQS_Queue_Event_Msg_Subscription" {
  topic_arn            = aws_sns_topic.New_S3_Obj_Uploaded_Event_Msg.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.sqs_fanout_new_s3_obj_event.arn
}

###################################################
###################################################

###################
#    S3 Buckets   #
###################

#Create Source S3 Bucket
resource "aws_s3_bucket" "sqs_fan_out_bucket_ljabad" {
  bucket = var.source_s3bucket_name
  force_destroy = true
}

#Create Resized Destrination S3 Bucket
resource "aws_s3_bucket" "sqs_fan_out_bucket_ljabad_resized" {
  bucket = "${var.source_s3bucket_name}-resized"
  force_destroy = true
}

#Attach Event Notification: S3 bucket source to SNS Topic
resource "aws_s3_bucket_notification" "sqs_fan_out_new_s3_obj_msg_ljabad" {
  bucket = aws_s3_bucket.sqs_fan_out_bucket_ljabad.id

  topic {
    topic_arn     = aws_sns_topic.New_S3_Obj_Uploaded_Event_Msg.arn
    events        = ["s3:ObjectCreated:*"]
    
  }
}
###################################################
###################################################

###################
#    SQS_Queue    #
###################

#create SQS_Queue
resource "aws_sqs_queue" "sqs_fanout_new_s3_obj_event" {
  name                      = "sqs_fanout_new_s3_obj_event"
  delay_seconds             = 0
  max_message_size          = 1024000
  message_retention_seconds = 345600
  receive_wait_time_seconds = 0
  visibility_timeout_seconds = 120
}

#SQS_Policy
data "aws_iam_policy_document" "sqs_allow_sns" {
  statement {
    sid     = "AllowSNSPublish"
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.sqs_fanout_new_s3_obj_event.arn]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.New_S3_Obj_Uploaded_Event_Msg.arn]
    }

  }
}

#Attach SQS_Policy to SQS_Queue
resource "aws_sqs_queue_policy" "sqs_allow_sns_policy" {
  queue_url = aws_sqs_queue.sqs_fanout_new_s3_obj_event.id
  policy    = data.aws_iam_policy_document.sqs_allow_sns.json
}

###################################################
###################################################


###################
#      Lambda     #
###################
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

# Attach AmazonS3FullAccess to the Role created
resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role      = aws_iam_role.lambda_s3_sqs_allow_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Attach AmazonSQSFullAccess to the Role created
resource "aws_iam_role_policy_attachment" "sqs_full_access" {
  role      = aws_iam_role.lambda_s3_sqs_allow_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

# Attach AWSLambdaBasicExecutionRole to the Role created
resource "aws_iam_role_policy_attachment" "AWSLambdaBasicExecutionRole" {
  role      = aws_iam_role.lambda_s3_sqs_allow_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#Create Lambda_Function and attach the deployment package (lambda_function.zip) located on the root folder of this project
resource "aws_lambda_function" "SQS_Fanout_Assignment" {
  filename      = "${path.module}/lambda_function.zip"
  function_name = "SQS-Fanout-Assignment"
  role          = aws_iam_role.lambda_s3_sqs_allow_role.arn 
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.14"

  timeout      = 60
  memory_size = 1024
}

# Add the created SQS_Que as Lambda Trigger
resource "aws_lambda_event_source_mapping" "SQS_Trigger" {
  event_source_arn = aws_sqs_queue.sqs_fanout_new_s3_obj_event.arn
  function_name    = aws_lambda_function.SQS_Fanout_Assignment.arn
  batch_size       = 10
}

###################################################
###################################################