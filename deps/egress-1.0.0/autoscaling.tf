
data "aws_ami" "latest_amzn_ecs_ami" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "architecture"
//    values = ["arm64"]
    values = ["x86_64"]
  }

  filter {
    name = "name"
    values = ["amzn2-ami-ecs-hvm-*-ebs"]
  }
}

resource "aws_autoscaling_group" "ecs_instances" {
  name = "${var.app_name}-${data.aws_region.current.name}-egress-autoscaling-group"
  launch_configuration = aws_launch_configuration.ecs_instance_configuration.id
  vpc_zone_identifier = var.public_subnet_ids
  max_size = length(var.public_subnet_ids)
  min_size = length(var.public_subnet_ids)

  instance_refresh {
    strategy = "Rolling"
  }

  tags = flatten([
      [for key in keys(var.standard_tags_no_name) :
        {
          key: key,
          value: var.standard_tags_no_name[key],
          propagate_at_launch: true,
        }
      ],
      [
        {
          key: "Name",
          value: "${var.app_name}-egress",
          propagate_at_launch: true,
        },
        {
          key: "ecs-cluster-name",
          value: "{aws_ecs_cluster.main.name}",
          propagate_at_launch: true,
        }
      ]
    ])

}

resource "aws_security_group" "ecs_instance_sg" {
  name = "${var.app_name}-${data.aws_region.current.name}-egress-instance-sg"
  description = "${var.app_name}-${data.aws_region.current.name}-ecs-instance-sg"
  vpc_id = data.aws_vpc.this.id

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [data.aws_vpc.this.cidr_block]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.app_name}-${data.aws_region.current.name}-egress_ecs_role"
  assume_role_policy = data.aws_iam_policy_document.iam_instance_role_assume_policy_document.json
  inline_policy {}
  managed_policy_arns = [
    aws_iam_policy.iam_instance_policy.arn,
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

data "aws_iam_policy_document" "iam_instance_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:ModifyInstanceAttribute",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "iam_instance_policy" {
//  role = aws_iam_role.ecs_instance_role.name
  name = "${var.app_name}-${data.aws_region.current.name}-ecs-instance-role-policy"
  policy = data.aws_iam_policy_document.iam_instance_policy_document.json
}

//resource "aws_iam_role_policy_attachment" "iam"

data "aws_iam_policy_document" "iam_instance_role_assume_policy_document" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

//resource "aws_iam_role_policy_attachment" "ecs_instance_ecs_role_attachment" {
//  role = aws_iam_role.ecs_instance_role.name
//  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
//}
//
//resource "aws_iam_role_policy_attachment" "ecs_instance_ssm_role_attachment" {
//  role = aws_iam_role.ecs_instance_role.name
//  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
//}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.app_name}-${data.aws_region.current.name}-egress_ecs_instance_profile"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_launch_configuration" "ecs_instance_configuration" {
  name_prefix = "${var.app_name}-${data.aws_region.current.name}-egress"
  security_groups = [aws_security_group.ecs_instance_sg.id]
  image_id = data.aws_ami.latest_amzn_ecs_ami.id
//  instance_type = "t4g.nano"
  instance_type = "t3a.nano"
  iam_instance_profile = aws_iam_instance_profile.ecs_instance_profile.name
  associate_public_ip_address = false
  user_data = templatefile("${path.module}/templates/setup_nat_iptables.sh", {
  })

  lifecycle {
    create_before_destroy = true
  }
}
