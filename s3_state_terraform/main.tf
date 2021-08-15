terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  region = "us-west-2"
  alias = "usw2"
}

module "us-east-1" {
  source = "./region_state"
}

module "us-west-2" {
  source = "./region_state"
  providers = {
    aws = aws.usw2
  }
}
