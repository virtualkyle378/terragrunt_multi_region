locals {

}

terraform {
  source = "../../../../deps//egress-1.0.0"
}

dependency "vpc" {
  config_path = "../vpc"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
  public_subnet_ids = dependency.vpc.outputs.public_subnet_ids
  standard_tags_no_name = dependency.vpc.outputs.standard_tags_no_name
}