output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.openhands.id
}

output "instance_public_ip" {
  description = "Elastic IP address"
  value       = aws_eip.openhands_eip.public_ip
}

output "instance_public_dns" {
  description = "Elastic IP DNS name"
  value       = aws_eip.openhands_eip.public_dns
}

output "openhands_url" {
  description = "OpenHands web interface URL"
  value       = "http://${aws_eip.openhands_eip.public_dns}:${local.config.openhands.port}"
}

output "ssh_command" {
  description = "SSH command to connect to instance"
  value       = "ssh -i keys/openhands-key.pem ec2-user@${aws_eip.openhands_eip.public_dns}"
}

output "current_ip" {
  description = "Current public IP allowed for SSH"
  value       = local.current_ip
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.openhands.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = aws_subnet.private.id
}