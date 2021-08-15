locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  region = local.region_vars.locals.region
  repo_name = "terragrunt_multi_region"
  app_name = "tg-mr"
}

inputs = merge(
  local.region_vars.locals,
  local.environment_vars.locals,
  local.account_vars.locals,
  {
    "repo_name": local.repo_name
    "app_name": local.app_name
  }
)

remote_state {
  backend = "s3"
  generate = {
    path = "state.tf"
    if_exists = "overwrite"
  }

  config = {
    bucket = "${local.account_vars.locals.state_bucket}"
    region = "${local.region}"
    key = "terragrunt_multi_region/${path_relative_to_include()}/terraform.tfstate"
    dynamodb_table = "${local.account_vars.locals.state_lock_dynamodb_table}"
  }
}

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" {
  region = "${local.region}"
}
EOF
}

generate "versions" {
  path = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.47.0"
    }
  }

  required_version = ">= 1.0.0"
}
EOF
}