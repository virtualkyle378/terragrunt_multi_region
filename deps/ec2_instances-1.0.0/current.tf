
data "aws_partition" "current" {}
data "aws_region" "current" {}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}
