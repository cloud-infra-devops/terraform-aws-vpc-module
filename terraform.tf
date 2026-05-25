# Your configuration does not need a cloud block for VCS-driven workspaces. HCP Terraform handles the backend automatically when you connect your VCS repository to HCP Terraform. You can remove the cloud block from your configuration, and HCP Terraform will manage the backend for you.
terraform {
  required_version = "~> 1.15.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.46.0"
    }
  }
}

provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.aws_account_id]
}
