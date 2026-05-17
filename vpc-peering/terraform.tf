terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.45.0"
    }
  }

# UNCOMMENT ONLY AFTER FIRST RUN (WHEN TF STATE SAVED IN S3 BUCKET)
  backend "s3" {
    bucket         = "vpc-peering-state-bucket"
    key            = "global/s3/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
  }

  required_version = ">= 1.2"
}

# Provider for the primary region (us-east-1)
provider "aws" {
  region = var.primary_region
  alias  = "primary_region"
}

# Provider for the secondary region (us-west-2)
provider "aws" {
  region = var.secondary_region
  alias  = "secondary_region"
}
