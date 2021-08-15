
data "aws_partition" "current" {}
data "aws_region" "current" {}

data "aws_vpc" "this" {
  id = var.vpc_id
}
