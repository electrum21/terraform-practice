provider "aws" {
  region = var.aws_region
}

# IMPORTANT: ONLY UNCOMMENT/RUN BELOW AFTER S3 BUCKET HAS BEEN CREATED FOR STORING TF STATE

# Create a S3 Bucket for storing the web app
resource "aws_s3_bucket" "mybucket" {
  bucket = var.bucket_name
}

# To make S3 Bucket access private, require the public_access_block
resource "aws_s3_bucket_public_access_block" "myblock" {
  bucket = aws_s3_bucket.mybucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# For origin access control
resource "aws_cloudfront_origin_access_control" "myoac" {
  name                              = "demo-myoac"
  description                       = "Example Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Create a bucket policy
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.mybucket.id
  # CRITICAL: Force Terraform to wait until BOTH the public access block 
  # AND the CloudFront Distribution are completely created before applying the policy.
  depends_on = [
    aws_s3_bucket_public_access_block.myblock,
    aws_cloudfront_distribution.s3_distribution
  ]
  policy = jsonencode(
      {
      "Version": "2012-10-17",
      Statement = [
        {
          Sid    = "AllowCloudFrontServicePrincipal"
          Effect = "Allow"
          Principal = {
            Service = "cloudfront.amazonaws.com"
          }
          Action   = "s3:GetObject"
          Resource = "${aws_s3_bucket.mybucket.arn}/*"
          Condition = {
            StringEquals = {
              "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
            }
          }
        }
      ]
    }
  )
}


# Create a S3 Bucket Object
resource "aws_s3_object" "website_files" {
  for_each = fileset("${path.module}/www", "**/*") # For each loop to upload each of the files in www folder
  
  bucket = aws_s3_bucket.mybucket.id
  key    = each.value
  source = "${path.module}/www/${each.value}"
  etag = filemd5("${path.module}/www/${each.value}")
  content_type = lookup({
    "html" = "text/html",
    "css"  = "text/css",
    "js"   = "application/javascript",
    "json" = "application/json",
    "png"  = "image/png",
    "jpg"  = "image/jpeg",
    "jpeg" = "image/jpeg",
    "gif"  = "image/gif",
    "svg"  = "image/svg+xml",
    "ico"  = "image/x-icon",
    "txt"  = "text/plain"
  }, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
}

# Create the CloudFront distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.mybucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.myoac.id
    origin_id                = "S3-${aws_s3_bucket.mybucket.id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront Distribution for cloudfront-static-web-app"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.mybucket.id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600 # in seconds
    max_ttl                = 86400 # time the data is cached in the edge location
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


# # =======================================================================================

# # IMPORTANT: CREATE S3 BUCKET FOR STORING STATE FILE

# resource "aws_s3_bucket" "terraform_state" {
#   bucket = "cloudfront-static-web-app-state-bucket" # Must be globally unique

#   # Prevent accidental deletion of this bucket
#   lifecycle {
#     prevent_destroy = true
#   }
# }

# # Enable versioning so you can see the full revision history of your state files
# resource "aws_s3_bucket_versioning" "enabled" {
#   bucket = aws_s3_bucket.terraform_state.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# # Enable server-side encryption by default
# resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
#   bucket = aws_s3_bucket.terraform_state.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

# # Block all public access to the bucket
# resource "aws_s3_bucket_public_access_block" "public_access" {
#   bucket                  = aws_s3_bucket.terraform_state.id
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }