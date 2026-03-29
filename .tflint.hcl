# https://gist.githubusercontent.com/guivin/bcf328481350c6fc97ffbdcf832573f9/raw/21c513ad05af066559141f3edf022df29ad7e9e0/.tflint.hcl
# https://github.com/terraform-linters/tflint-ruleset-aws
plugin "aws" {
  enabled = true
  version = "0.44.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
plugin "terraform" {
  enabled          = true
  version          = "0.13.0"
  source           = "github.com/terraform-linters/tflint-ruleset-terraform"
  call_module_type = "all"
}
config {
  force               = false
  call_module_type    = "all" # or "local"
  disabled_by_default = false
}

# Disallow deprecated (0.11-style) interpolation
rule "terraform_deprecated_interpolation" {
  enabled = true
}

# Disallow legacy dot index syntax
rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
}

rule "terraform_module_version" {
  enabled = true
  exact   = false # default
}

rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_unused_required_providers" {
  enabled = true
}

rule "aws_resource_missing_tags" {
  enabled = true
  tags = [
    "Project",
    "Environment",
    "Owner",
  ]
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "none"
  locals {
    format = "snake_case"
  }
}

rule "aws_instance_invalid_type" {
  enabled = true
}
