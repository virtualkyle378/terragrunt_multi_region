output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnets[*].id
}

output "standard_tags_no_name" {
  value = local.standard_tags_no_name
}

//output "public_subnet_ids" {
//  value = public_subnet_ids
//}
//
//output "private_subnet_ids" {
//  value = private_subnet_ids
//}
