resource "aws_route53_zone" "aws_snipercow_com" {
  name = "aws.snipercow.com"

  tags = merge(var.standard_tags_no_name, { Name: "aws.snipercow.com"})
}

//resource "aws_route53_record" "aws_snipercow_com_ns" {
//  name = "aws.snipercow.com"
//  zone_id = aws_route53_zone.aws_snipercow_com.id
//  records = aws_route53_zone.aws_snipercow_com.name_servers
//  type = "NS"
//  ttl = "30"
//}


//resource "aws_route53_record" "nexus_aws_snipercow_com" {
//  name = "nginx.aws.snipercow.com"
//  zone_id = aws_route53_zone.aws_snipercow_com.id
//  type = "CNAME"
//  ttl = "30"
//  records = [each.value]
//
//  for_each = toset([module.lb_ecs.nginx_ecs_ingress_lb_dns_name, module.lb_ecs_west2.nginx_ecs_ingress_lb_dns_name])
//}

resource "aws_route53_record" "nginx_aws_snipercow_com" {
  for_each = var.dns_data

  name = "nginx.aws.snipercow.com"
  zone_id = aws_route53_zone.aws_snipercow_com.id
  type = "A"
  set_identifier = "www${each.key}"

//  weighted_routing_policy {
//    weight = 1
//  }
  latency_routing_policy {
    region = each.key
  }

  alias {
    name = each.value["nginx_ecs_ingress_lb_dns_name"]
    zone_id = each.value["nginx_ecs_ingress_lb_zone_id"]
    evaluate_target_health = true
  }
}

//resource "aws_route53_record" "nexus_aws_snipercow_com_2" {
//  name = "nginx.aws.snipercow.com"
//  zone_id = aws_route53_zone.aws_snipercow_com.id
//  type = "A"
//  set_identifier = "www2"
//
////  weighted_routing_policy {
////    weight = 1
////  }
//
//  latency_routing_policy {
//    region = "us-west-2"
//  }
//
//  alias {
//    name = module.lb_ecs_west2.nginx_ecs_ingress_lb_dns_name
//    zone_id = module.lb_ecs_west2.nginx_ecs_ingress_lb_zone_id
//    evaluate_target_health = true
//  }
//}