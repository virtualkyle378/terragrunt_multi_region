resource "aws_security_group" "nginx_ecs_ingress_lb_sg" {
  name        = "nginx_ecs_ingress_lb_sg"
  description = "Allow TLS inbound traffic to nginx ecs"
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
}

resource "aws_lb" "nginx_ecs_ingress_lb" {
  name               = "nginx-ecs-ingress-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.nginx_ecs_ingress_lb_sg.id]
  //  vpc_id = aws_vpc.vpc.id
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  //  access_logs {
  //    bucket  = aws_s3_bucket.lb_logs.bucket
  //    prefix  = "test-lb"
  //    enabled = true
  //  }

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "nginx_ecs_ingress_tg" {
  name     = "nginx-ecs-ingress-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.vpc.id
  target_type = "ip"
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.nginx_ecs_ingress_lb.arn
  port              = "80"
  protocol          = "HTTP"
  //  ssl_policy        = "ELBSecurityPolicy-2016-08"
  //  certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_ecs_ingress_tg.arn
  }
}
