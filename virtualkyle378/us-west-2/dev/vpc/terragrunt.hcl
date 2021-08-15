locals {

}

terraform {
  source = "../../../../deps//vpc-1.0.0"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  vpc_cidr_block = "10.1.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
}