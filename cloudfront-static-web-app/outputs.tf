output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront Distribution"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}