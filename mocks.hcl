locals {
  vpc_id = "mock_vpc_id"
  vpc_cidr_block = "10.10.0.0/16"
  tags = {}
  private_subnet_ids = ["mock_a", "mock_b", "mock_c"]
  private_subnet_cidr_blocks = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  instance_security_group_id = "mock_security_group_id"
  bucket = "mock_bucket"
  internal_garget_group_arn = "arn:aws:service:us-east-1:000000000000:mock"
  route52_zone_id = "ABC123"
}