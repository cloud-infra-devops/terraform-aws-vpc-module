# https://builder.aws.com/content/2uLaePMiQZWbyHqmtiP9aKYoyls/automating-code-reviews-with-amazon-q-and-github-actions

# Amazon Q Developer Rules — terraform-aws-vpc-module

These rules guide Amazon Q when reviewing, generating, or modifying Terraform code in this repository.

## Module Purpose

This module creates a production-ready AWS VPC with:
- Public subnets (with Internet Gateway)
- Private subnets across N layers (app, db, cache, etc.)
- Optional NAT Gateway (single or one-per-AZ)
- Optional VPC Flow Logs → CloudWatch Logs
- CloudWatch alarms for NAT Gateway metrics and flow log delivery errors

---

## Terraform Code Standards

### Resource Naming
- All resources MUST use `merge(local.common_tags, { Name = "..." })` for tags.
- Resource name tags MUST follow the pattern: `${var.name}-<resource-type>[-<index>]`.
- Never hardcode environment, project, or owner values — always reference `var.environment`, `var.project`, `var.owner`.

### Variable Definitions
- Every variable MUST have a `description` and `type`.
- Variables with constrained values MUST include a `validation` block with a clear `error_message`.
- Boolean variables controlling optional features MUST default to a safe/conservative value (e.g., `enable_flow_logs = true`, `create_nat_gateway = true`).
- Do not add new required variables (no `default`) without updating `examples/main.tf` and `README.md`.

### Conditional Resource Creation
- Use `count = var.<flag> ? <n> : 0` for optional resources.
- Never use `for_each` with a value that can be `null` without a null guard.
- Routes to `0.0.0.0/0` on private subnets MUST only be created when `create_nat_gateway = true`.

### CIDR Allocation
- Subnets MUST be carved using `cidrsubnet(var.vpc_cidr, 8, <index>)`.
- Public subnets occupy indices `0..(num_public_subnets - 1)`.
- Private subnets start at index `num_public_subnets` and continue sequentially across all layers.
- Do not overlap CIDR blocks between public and private subnets.

### Security
- `map_public_ip_on_launch` MUST be `false` on all subnets (public and private).
- The default security group (`aws_default_security_group`) MUST be managed by Terraform with no ingress/egress rules.
- Do not add `0.0.0.0/0` ingress rules to any security group in this module.
- Flow logs MUST be enabled by default (`enable_flow_logs = true`).
- DNS hostnames and DNS support MUST be enabled by default.

### NAT Gateway
- When `single_nat_gateway = false`, create one NAT GW per public subnet (one per AZ).
- When `single_nat_gateway = true`, create exactly one NAT GW in the first public subnet.
- EIPs for NAT gateways MUST use `domain = "vpc"`.
- NAT gateway resources MUST declare `depends_on = [aws_internet_gateway.this]`.

### Flow Logs
- Flow logs MUST target a CloudWatch Logs group when enabled.
- The IAM role for flow logs MUST use a least-privilege policy (only `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`, `logs:DescribeLogGroups`, `logs:DescribeLogStreams`).
- Log group retention MUST be configurable via `var.flow_logs_retention_days` (default: 30).

### CloudWatch Alarms
- NAT Gateway alarms MUST only be created when `create_nat_gateway = true`.
- Flow log alarms MUST only be created when `enable_flow_logs = true`.
- All alarms MUST reference `var.cloudwatch_alarm_actions` for notification actions.
- Do not hardcode SNS ARNs.

---

## Module Interface Rules

### Outputs
- Every output MUST have a `description`.
- Outputs for optional resources (NAT GW, flow logs) MUST return `null` (not error) when the resource is not created.
- Do not remove existing outputs — they are part of the public module interface.

### Backwards Compatibility
- Do not rename existing variables or outputs.
- Do not change the default value of any existing variable without a major version bump.
- New optional variables MUST have a default value so existing callers are unaffected.

---

## File Structure

| File                   | Purpose                                       |
| ---------------------- | --------------------------------------------- |
| `main.tf`              | VPC, subnets, IGW, NAT GW, route tables       |
| `flow_logs.tf`         | VPC Flow Logs, IAM role, CloudWatch log group |
| `cloudwatch_alarms.tf` | CloudWatch alarms for NAT GW and flow logs    |
| `variables.tf`         | All input variable declarations               |
| `outputs.tf`           | All output declarations                       |
| `versions.tf`          | Terraform and provider version constraints    |
| `examples/main.tf`     | Working example showing all key inputs        |

- Do not merge resources from different functional areas into the same file.
- Keep `versions.tf` pinned to `>= 1.14.0` for Terraform and `>= 6.0` for the AWS provider.

---

## VPC CIDR Design

- `vpc_cidr` MUST use a private RFC 1918 range: `10.0.0.0/8`, `172.16.0.0/12`, or `192.168.0.0/16`.
- The VPC prefix length MUST be between `/16` and `/24` — never use `/8` (too broad) or `/28` or smaller (too narrow for subnetting).
- `secondary_vpc_cidr` MUST NOT overlap with `vpc_cidr` or any other associated CIDR block.
- Do not use `100.64.0.0/10` (CGNAT range) as a primary VPC CIDR — it is reserved for carrier-grade NAT and may cause routing conflicts.
- When a secondary CIDR is added, document the reason in a comment above `aws_vpc_ipv4_cidr_block_association`.

---

## Subnet Design

- Every subnet MUST be associated with exactly one route table — never leave a subnet implicitly associated with the main route table.
- Public subnets MUST be associated with a route table that has a `0.0.0.0/0` route to the Internet Gateway.
- Private subnets MUST NOT have a direct route to the Internet Gateway.
- Subnet CIDR blocks MUST NOT be larger than `/24` — keep them predictable and consistently sized.
- Each private subnet layer MUST have a `Tier = "private"` and `Layer = "<n>"` tag to identify its purpose.
- Do not create subnets in more AZs than are available in the target region — always use `data.aws_availability_zones.available`.
- `availability_zone` on subnets MUST be assigned dynamically using `data.aws_availability_zones.available`, never hardcoded (e.g., never `"us-east-1a"`).

---

## Internet Gateway

- Only one Internet Gateway MUST be attached per VPC — never create more than one `aws_internet_gateway` for the same VPC.
- The IGW MUST be tagged with `Name = "${var.name}-igw"`.
- All public route tables MUST reference the IGW for `0.0.0.0/0` — never route public traffic through a NAT Gateway.

---

## Route Tables

- The main (default) route table MUST NOT be used for any subnet — always create explicit route tables.
- Each private subnet MUST have its own route table to allow per-subnet routing control.
- Do not add routes to `0.0.0.0/0` on private route tables unless `create_nat_gateway = true`.
- Do not add IPv6 routes unless IPv6 is explicitly enabled on the VPC.
- Route table names MUST follow the pattern `${var.name}-public-rt` and `${var.name}-private-rt-<index>`.

---

## Network ACLs

- Do not create custom Network ACLs (NACLs) in this module — rely on security groups for traffic control.
- If NACLs are added in future, they MUST be managed by Terraform (never left as AWS defaults).
- Never create a NACL rule that allows `0.0.0.0/0` inbound on port 22 (SSH) or port 3389 (RDP).

---

## VPC Endpoints

- If VPC Endpoints are added, use Gateway endpoints (free) for S3 and DynamoDB before considering Interface endpoints.
- Interface endpoints MUST be placed in private subnets only.
- VPC Endpoint policies MUST follow least-privilege — do not use `"*"` as the principal in endpoint policies.
- VPC Endpoint resources belong in `main.tf` under a clearly marked section comment.

---

## VPC Peering

- Do not create VPC Peering connections inside this module — peering is a cross-VPC concern and belongs in a separate module.
- Do not add routes for peered VPC CIDRs in this module's route tables.

---

## IPv6

- Do not enable IPv6 (`assign_ipv6_address_on_creation`, `ipv6_cidr_block`) unless explicitly required — keep the module IPv4-only by default.
- If IPv6 is added, it MUST be controlled by a new boolean variable `enable_ipv6` defaulting to `false`.
- An Egress-Only Internet Gateway MUST be used for IPv6 outbound traffic from private subnets — never use the standard IGW for private IPv6 egress.

---

## Tagging

- Every resource MUST include at minimum: `Name`, `Environment`, `Project`, `Owner` tags via `local.common_tags`.
- Subnet tags MUST include a `Tier` tag (`"public"` or `"private"`) to support tag-based subnet discovery by EKS, ELB, and other AWS services.
- Private subnets intended for EKS node groups MUST include `"kubernetes.io/role/internal-elb" = "1"`.
- Public subnets intended for EKS load balancers MUST include `"kubernetes.io/role/elb" = "1"`.
- These EKS tags MUST only be added when a new boolean variable `tag_subnets_for_eks` is `true` (default: `false`).

---

## What to Avoid

- Do not use `terraform_remote_state` data sources inside this module.
- Do not create resources outside the VPC networking domain (no EC2 instances, RDS, etc.).
- Do not use `count` and `for_each` on the same resource.
- Do not use deprecated AWS provider attributes (e.g., `aws_eip.vpc = true` — use `domain = "vpc"`).
- Do not suppress linting or security scan findings without a documented justification comment.
- Do not hardcode AWS account IDs, region names, or AZ names anywhere in `.tf` files.
- Do not create a default route (`0.0.0.0/0`) in the VPC main route table.
- Do not associate the same subnet with more than one route table.
