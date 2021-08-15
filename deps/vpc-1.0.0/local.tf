locals {
  public_subnet_cidrs = [for i in range(0, length(var.availability_zones)): cidrsubnet(var.vpc_cidr_block, 8, i)]
  private_subnet_cidrs = [for i in range(0, length(var.availability_zones)): cidrsubnet(var.vpc_cidr_block, 8, i + 128)]
}