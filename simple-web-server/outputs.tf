output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web-server-instance.public_ip
}

output "instance_id" {
  value = aws_instance.web-server-instance.id
}