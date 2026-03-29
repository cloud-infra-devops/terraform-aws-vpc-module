# ─── EXAMPLE: terraform-aws-vpc module usage ────────────────────────────────
#
# This example shows all required and optional inputs, and captures all outputs.
# Run:
#   terraform init
#   terraform plan
#   terraform apply

terraform {
  required_version = ">= 1.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../"

  # ── Required inputs ────────────────────────────────────────────────────────
  aws_region = "us-east-1"
  vpc_cidr   = "10.0.0.0/16"

  # ── Optional: naming & tagging ─────────────────────────────────────────────
  name = "example-app"

  tags = {
    Environment = "dev"
    Team        = "platform"
  }

  # ── Optional: subnet layout ────────────────────────────────────────────────
  num_public_subnets  = 3         # one per AZ
  num_private_subnets = 3         # subnets per layer, per AZ
  num_layers          = 2         # layer-1 = app, layer-2 = db
  instance_tenancy    = "default" # "default" | "dedicated" | "host"

  # ── Optional: secondary CIDR (set to null to skip) ─────────────────────────
  secondary_vpc_cidr = "100.64.0.0/16"

  # ── Optional: DNS settings ─────────────────────────────────────────────────
  enable_dns_hostnames = true
  enable_dns_support   = true

  # ── Optional: NAT Gateway ──────────────────────────────────────────────────
  # Routes to 0.0.0.0/0 on private subnets are created ONLY when this is true.
  create_nat_gateway = true
  single_nat_gateway = false # false = one NAT GW per AZ; true = single shared NAT GW

  # ── Optional: VPC Flow Logs ────────────────────────────────────────────────
  enable_flow_logs         = true
  flow_logs_retention_days = 30

  # ── Optional: CloudWatch alarm notifications ───────────────────────────────
  # Provide SNS topic ARNs to receive alarm notifications.
  # Leave as [] to create alarms without notification actions.
  cloudwatch_alarm_actions = []
}

# ─── OUTPUTS ────────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "Primary CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "secondary_cidr_block" {
  description = "Secondary CIDR block (null if not created)"
  value       = module.vpc.secondary_cidr_block
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = module.vpc.internet_gateway_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "All private subnet IDs across all layers"
  value       = module.vpc.private_subnet_ids
}

output "private_subnet_ids_by_layer" {
  description = "Map of layer number → list of private subnet IDs"
  value       = module.vpc.private_subnet_ids_by_layer
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs (empty list if create_nat_gateway = false)"
  value       = module.vpc.nat_gateway_ids
}

output "nat_gateway_public_ips" {
  description = "Elastic IPs assigned to NAT Gateways"
  value       = module.vpc.nat_gateway_public_ips
}

output "public_route_table_id" {
  description = "Public route table ID"
  value       = module.vpc.public_route_table_id
}

output "private_route_table_ids" {
  description = "Private route table IDs"
  value       = module.vpc.private_route_table_ids
}

output "flow_log_id" {
  description = "VPC Flow Log ID (null if enable_flow_logs = false)"
  value       = module.vpc.flow_log_id
}

output "flow_log_cloudwatch_log_group" {
  description = "CloudWatch Log Group name for flow logs (null if enable_flow_logs = false)"
  value       = module.vpc.flow_log_cloudwatch_log_group
}
