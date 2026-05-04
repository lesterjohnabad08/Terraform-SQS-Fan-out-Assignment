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