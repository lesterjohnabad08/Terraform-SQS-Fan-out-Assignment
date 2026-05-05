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

#Create SNS Topic
resource "aws_sns_topic" "New-S3-Obj-Uploaded-Event-Msg" {
  name = "New-S3-Obj-Uploaded-Event-Msg"
}

resource "aws_sns_topic_subscription" "New-S3-Obj-Uploaded-Event-Msg-Subscription" {
  topic_arn            = aws_sns_topic.New-S3-Obj-Uploaded-Event-Msg.arn
  protocol             = "email"
  endpoint             = var.email_address
}

resource "aws_s3_bucket" "sqs-fan-out-bucket-ljabad" {
  bucket = "sqs-fan-out-bucket-ljabad"

}

resource "aws_iam_role" "lambda_s3_allow_role" {
  name = "lambda-s3-allow-role"

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
    Name = "Lambda-S3-Allow-Role"
  }
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role      = aws_iam_role.lambda_s3_allow_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

#Editing this

#resource "aws_lambda_function" "example" {
 # filename      = "${path.module}/lambda.zip"
 # function_name = "example_lambda_function"
 # role          = aws_iam_role.example.arn 
 # handler       = "lambda_function.handler"
 # runtime       = "python3.12"

#}