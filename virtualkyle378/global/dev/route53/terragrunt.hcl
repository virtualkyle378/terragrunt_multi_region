locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../../deps//route53-1.0.0"
}

dependency "us-east-1_vpc" {
  config_path = "../../../us-east-1/${local.environment_vars.locals.environment}/vpc"
}

dependency "us-east-1_lb_ecs" {
  config_path = "../../../us-east-1/${local.environment_vars.locals.environment}/lb_ecs"
}

dependency "us-west-2_lb_ecs" {
  config_path = "../../../us-west-2/${local.environment_vars.locals.environment}/lb_ecs"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  dns_data = {
    "us-east-1": {
      "nginx_ecs_ingress_lb_dns_name": dependency.us-east-1_lb_ecs.outputs.nginx_ecs_ingress_lb_dns_name
      "nginx_ecs_ingress_lb_zone_id": dependency.us-east-1_lb_ecs.outputs.nginx_ecs_ingress_lb_zone_id
    }
    "us-west-2": {
      "nginx_ecs_ingress_lb_dns_name": dependency.us-west-2_lb_ecs.outputs.nginx_ecs_ingress_lb_dns_name
      "nginx_ecs_ingress_lb_zone_id": dependency.us-west-2_lb_ecs.outputs.nginx_ecs_ingress_lb_zone_id
    }
  },
  standard_tags_no_name = dependency.us-east-1_vpc.outputs.standard_tags_no_name
}