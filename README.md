# terraform-aws-vpc

A Terraform module that creates a production-ready AWS VPC with public/private subnets across multiple layers, optional NAT Gateway, optional VPC Flow Logs, and CloudWatch alarms.

## Features

- VPC with optional secondary CIDR block
- Configurable public subnets (with Internet Gateway)
- Configurable private subnets across N layers (e.g. app, db, cache)
- Optional NAT Gateway (single or one-per-AZ) with 0.0.0.0/0 routes on private subnets **only when NAT is created**
- Optional VPC Flow Logs → CloudWatch Logs
- CloudWatch alarms for NAT Gateway metrics and flow log delivery errors

## Usage

```hcl
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
  source = "github.com/cloud-infra-devops/terraform-aws-vpc-module?ref=v1.0.2"

  # ── Required inputs ────────────────────────────────────────────────────────
  aws_region = "us-west-2"
  vpc_cidr   = "10.0.0.0/16"

  # ── Optional: naming & tagging ─────────────────────────────────────────────
  name        = "duke-aim-ima"
  environment = "dev"
  owner       = "cloud-infra-devops"
  project     = "duke-data-aim-ima"

  tags = {
    Email = "cloud-infra-devops@duke-energy.com"
    Team  = "Cloud DevOps Platform Engineering"
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
  create_nat_gateway = false
  single_nat_gateway = false # false = one NAT GW per AZ; true = single shared NAT GW

  # ── Optional: VPC Flow Logs ────────────────────────────────────────────────
  enable_flow_logs = true

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

```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `aws_region` | AWS region | `string` | — | yes |
| `name` | Name prefix for all resources | `string` | `"vpc"` | no |
| `vpc_cidr` | Primary VPC CIDR block | `string` | — | yes |
| `secondary_vpc_cidr` | Secondary VPC CIDR (null to skip) | `string` | `null` | no |
| `num_public_subnets` | Number of public subnets | `number` | `2` | no |
| `num_private_subnets` | Number of private subnets per layer | `number` | `2` | no |
| `num_layers` | Number of private subnet layers | `number` | `1` | no |
| `instance_tenancy` | VPC tenancy (default/dedicated/host) | `string` | `"default"` | no |
| `create_nat_gateway` | Create NAT Gateway | `bool` | `true` | no |
| `single_nat_gateway` | Use one NAT GW instead of one per AZ | `bool` | `false` | no |
| `enable_flow_logs` | Enable VPC Flow Logs | `bool` | `true` | no |
| `flow_logs_retention_days` | Flow log CW retention days | `number` | `30` | no |
| `enable_dns_hostnames` | Enable DNS hostnames | `bool` | `true` | no |
| `enable_dns_support` | Enable DNS support | `bool` | `true` | no |
| `cloudwatch_alarm_actions` | SNS ARNs for alarm notifications | `list(string)` | `[]` | no |
| `tags` | Common tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | VPC ID |
| `vpc_cidr_block` | Primary CIDR |
| `secondary_cidr_block` | Secondary CIDR (if created) |
| `internet_gateway_id` | IGW ID |
| `public_subnet_ids` | Public subnet IDs |
| `private_subnet_ids` | All private subnet IDs |
| `private_subnet_ids_by_layer` | Map of layer → subnet IDs |
| `nat_gateway_ids` | NAT Gateway IDs |
| `nat_gateway_public_ips` | NAT Gateway Elastic IPs |
| `public_route_table_id` | Public route table ID |
| `private_route_table_ids` | Private route table IDs |
| `flow_log_id` | Flow Log ID (null if disabled) |
| `flow_log_cloudwatch_log_group` | CW Log Group name (null if disabled) |

## CloudWatch Alarms

The following alarms are created automatically:

**Per NAT Gateway** (created only when `create_nat_gateway = true`):
- `ErrorPortAllocation` — SNAT port exhaustion (threshold: > 0)
- `PacketsDropCount` — dropped packets (threshold: > 100)
- `ConnectionAttemptCount` — high connection attempts (threshold: > 100,000 per 5 min)
- `ConnectionEstablishedCount` — zero established connections (threshold: < 1)
- `BytesOutToDestination` — high egress bytes (threshold: > 10 GB per 5 min)
- `BytesInFromDestination` — high ingress bytes (threshold: > 10 GB per 5 min)

**Flow Logs** (created only when `enable_flow_logs = true`):
- `DeliveryErrors` — flow log delivery failures
- `ThrottledEvents` — flow log throttling

## Subnet CIDR Layout

Subnets are carved from the VPC CIDR using `/24` blocks (`cidrsubnet(vpc_cidr, 8, index)`):

```
Index 0..N-1          → public subnets
Index N..N+L*P-1      → private subnets (L layers × P subnets each)
```

For a `10.0.0.0/16` VPC with 3 public + 2 layers × 3 private:
```
10.0.0.0/24  public-1
10.0.1.0/24  public-2
10.0.2.0/24  public-3
10.0.3.0/24  private-layer1-1
10.0.4.0/24  private-layer1-2
10.0.5.0/24  private-layer1-3
10.0.6.0/24  private-layer2-1
10.0.7.0/24  private-layer2-2
10.0.8.0/24  private-layer2-3
```
