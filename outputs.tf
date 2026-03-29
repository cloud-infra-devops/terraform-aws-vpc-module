output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "Primary CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "secondary_cidr_block" {
  description = "Secondary CIDR block (if created)"
  value       = var.secondary_vpc_cidr != null ? aws_vpc_ipv4_cidr_block_association.secondary[0].cidr_block : null
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of all private subnet IDs (all layers)"
  value       = aws_subnet.private[*].id
}

output "private_subnet_ids_by_layer" {
  description = "Map of layer number to list of private subnet IDs"
  value = {
    for l in range(var.num_layers) :
    tostring(l + 1) => [
      for s in range(var.num_private_subnets) :
      aws_subnet.private[l * var.num_private_subnets + s].id
    ]
  }
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs (empty if not created)"
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "List of Elastic IPs associated with NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = aws_route_table.private[*].id
}

output "flow_log_id" {
  description = "ID of the VPC Flow Log (null if not enabled)"
  value       = var.enable_flow_logs ? aws_flow_log.this[0].id : null
}

output "flow_log_cloudwatch_log_group" {
  description = "CloudWatch Log Group name for VPC flow logs (null if not enabled)"
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : null
}
