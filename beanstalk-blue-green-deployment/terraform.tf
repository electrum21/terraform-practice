terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.45.0"
    }
  }

# UNCOMMENT ONLY AFTER FIRST RUN (WHEN TF STATE SAVED IN S3 BUCKET)
  backend "s3" {
    bucket         = "beanstalk-blue-green-deployment-state-bucket"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }

  required_version = ">= 1.0"
}
