



output "vpc_id" {
  description = "The ID of the created VPC."
  value       = aws_vpc.main.id
}

output "management_subnet_id" {
  description = "The ID of the management subnet."
  value       = aws_subnet.management.id
}

output "jump_server_public_ip" {
  description = "The public IP address of the jump server."
  value       = aws_eip.jump_server_eip.public_ip
}


