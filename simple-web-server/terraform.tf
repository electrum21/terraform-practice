terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

# UNCOMMENT ONLY AFTER FIRST RUN (WHEN TF STATE SAVED IN S3 BUCKET)
  backend "s3" {
    bucket         = "simple-web-server-state-bucket"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }

  required_version = ">= 1.2"
}
