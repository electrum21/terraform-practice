variable "bucket_name" {
description = "Value of the S3 Bucket's Name tag."
  type        = string
  default     = "electrum21-app-bucket"
}

variable "aws_region" {
  description = "The AWS region to create resources in."
  type        = string
  default     = "us-east-1"
}