variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must be a valid AWS region (e.g. us-east-1, eu-west-2)."
  }
}

variable "vpc_cidr" {
  description = "Primary CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid CIDR block (e.g. 10.0.0.0/16)."
  }
}

variable "secondary_vpc_cidr" {
  description = "Optional secondary CIDR block for the VPC. Set to null to skip."
  type        = string
  default     = null

  validation {
    condition     = var.secondary_vpc_cidr == null || can(cidrnetmask(var.secondary_vpc_cidr))
    error_message = "secondary_vpc_cidr must be a valid CIDR block or null."
  }
}

variable "num_public_subnets" {
  description = "Number of public subnets to create"
  type        = number
  default     = 2

  validation {
    condition     = var.num_public_subnets >= 1 && var.num_public_subnets <= 8
    error_message = "num_public_subnets must be between 1 and 8."
  }
}

variable "num_private_subnets" {
  description = "Number of private subnets to create per layer"
  type        = number
  default     = 2

  validation {
    condition     = var.num_private_subnets >= 1 && var.num_private_subnets <= 8
    error_message = "num_private_subnets must be between 1 and 8."
  }
}

variable "num_layers" {
  description = "Number of private subnet layers (e.g. app layer, db layer)"
  type        = number
  default     = 1

  validation {
    condition     = var.num_layers >= 1 && var.num_layers <= 4
    error_message = "num_layers must be between 1 and 4."
  }
}

variable "instance_tenancy" {
  description = "Tenancy option for instances launched in the VPC (default, dedicated, host)"
  type        = string
  default     = "default"

  validation {
    condition     = contains(["default", "dedicated", "host"], var.instance_tenancy)
    error_message = "instance_tenancy must be one of: default, dedicated, host."
  }
}

variable "create_nat_gateway" {
  description = "Whether to create a NAT gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway instead of one per AZ"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Whether to create VPC flow logs"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "vpc"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.name)) && length(var.name) <= 32
    error_message = "name must contain only alphanumeric characters and hyphens, and be at most 32 characters."
  }
}

variable "environment" {
  description = "Environment name (e.g. production, staging, development)"
  type        = string
}

variable "project" {
  description = "Project name that owns this VPC"
  type        = string
}

variable "owner" {
  description = "Team or individual responsible for this VPC"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "cloudwatch_alarm_actions" {
  description = "List of ARNs to notify when a CloudWatch alarm fires"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.cloudwatch_alarm_actions : can(regex("^arn:aws[a-z-]*:sns:[a-z0-9-]+:[0-9]{12}:.+$", arn))])
    error_message = "All cloudwatch_alarm_actions must be valid SNS topic ARNs."
  }
}
