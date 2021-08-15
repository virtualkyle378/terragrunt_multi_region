output "nginx_ecs_ingress_lb_dns_name" {
  value = aws_lb.nginx_ecs_ingress_lb.dns_name
}

output "nginx_ecs_ingress_lb_zone_id" {
  value = aws_lb.nginx_ecs_ingress_lb.zone_id
}
