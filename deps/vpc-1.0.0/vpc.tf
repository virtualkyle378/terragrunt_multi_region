resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = merge(local.standard_tags_no_name, {"Name": "sc-${var.app_name}-${var.environment}"})
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.standard_tags_no_name, {"Name": "sc-${var.app_name}-${var.environment}-gw"})
}

# Public subnets

resource "aws_route_table" "public_subnet_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.standard_tags_no_name, { Name: "sc-${var.app_name}-${var.environment}-public-route-table"})
}

resource "aws_subnet" "public_subnets" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.standard_tags_no_name, {
    Name = "sc-${var.app_name}-${var.environment}-public-subnet-${var.availability_zones[count.index]}"
  })
}

resource "aws_route_table_association" "public_subnet_associations" {
  count = length(var.availability_zones)

  subnet_id = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_subnet_route_table.id
}

# Private subnets

resource "aws_route_table" "private_subnet_route_table" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.vpc.id

  tags = merge(local.standard_tags_no_name, { Name: "sc-${var.app_name}-${var.environment}-private-route-table"})
}

resource "aws_subnet" "private_subnets" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.standard_tags_no_name, {
    Name = "sc-${var.app_name}-${var.environment}-private-subnet-${var.availability_zones[count.index]}"
  })
}

resource "aws_route_table_association" "private_subnet_associations" {
  count = length(var.availability_zones)

  subnet_id = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_subnet_route_table[count.index].id
}

