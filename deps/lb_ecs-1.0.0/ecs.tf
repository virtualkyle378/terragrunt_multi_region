resource "aws_ecs_cluster" "kyles_ecs_cluster" {
  name = "kyles_ecs_cluster"
}

resource "aws_ecs_task_definition" "nginx" {
  family = "service"
  network_mode = "awsvpc"
  cpu = 256
  memory = 512
  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "nginx"
      //      cpu       = 10
      //      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }])
  requires_compatibilities = ["FARGATE"]
}

resource "aws_security_group" "iam_sg" {
  name        = "iam_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    //    description      = "TLS from VPC"
    //    from_port        = 443
    //    to_port          = 443
    //    protocol         = "tcp"
    //    cidr_blocks      = [aws_vpc.vpc_a.cidr_block]
    //    ipv6_cidr_blocks = [aws_vpc.vpc_a.ipv6_cidr_block]
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.standard_tags_no_name, { Name: "iam_sg" })
}

resource "aws_security_group" "kyle_ecs_nginx_sg" {
  name        = "kyle_ecs_nginx_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    //    cidr_blocks      = [aws_vpc.vpc.cidr_block]
    //    ipv6_cidr_blocks = [aws_vpc.vpc.ipv6_cidr_block]
    security_groups = [aws_security_group.iam_sg.id]
  }

  ingress {
    description = "HTTP from LB"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.nginx_ecs_ingress_lb_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_ecs_service" "nginx" {
  name = "nginx"
  cluster = aws_ecs_cluster.kyles_ecs_cluster.id
  task_definition = aws_ecs_task_definition.nginx.arn
  desired_count = length(var.private_subnet_ids)
  launch_type = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx_ecs_ingress_tg.arn
    container_name = "nginx"
    container_port = 80
  }

  network_configuration {
    subnets = var.private_subnet_ids
    security_groups = [aws_security_group.kyle_ecs_nginx_sg.id]
    assign_public_ip = false
  }

}
