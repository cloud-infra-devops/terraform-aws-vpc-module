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
module "vpc" {
  source = "./terraform-aws-vpc"

  aws_region          = "us-east-1"
  name                = "my-app"
  vpc_cidr            = "10.0.0.0/16"
  num_public_subnets  = 3
  num_private_subnets = 3
  num_layers          = 2          # e.g. layer 1 = app, layer 2 = db
  instance_tenancy    = "default"

  # Optional secondary CIDR
  secondary_vpc_cidr  = "100.64.0.0/16"

  # NAT Gateway
  create_nat_gateway  = true
  single_nat_gateway  = false      # one NAT GW per AZ

  # Flow Logs
  enable_flow_logs         = true
  flow_logs_retention_days = 30

  # CloudWatch alarm notifications
  cloudwatch_alarm_actions = ["arn:aws:sns:us-east-1:123456789012:alerts"]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
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
