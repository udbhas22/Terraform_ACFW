



output "eni_id" {
  description = "The ID of the created ENI."
  value       = aws_network_interface.this.id
}

output "private_ips" {
  description = "The private IP addresses assigned to the ENI."
  value       = aws_network_interface.this.private_ips
}


