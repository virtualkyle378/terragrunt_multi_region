resource "aws_security_group" "ssm_sg" {
  name        = "ssm_sg"
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

  tags = merge(var.standard_tags_no_name, { Name: "ssm_sg" })
}

resource "aws_vpc_endpoint" "ssm_endpoint" {
  vpc_id = data.aws_vpc.vpc.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.ssm"
  subnet_ids = var.private_subnet_ids
  private_dns_enabled = true
  vpc_endpoint_type = "Interface"
  security_group_ids = [aws_security_group.ssm_sg.id]

  tags = merge(var.standard_tags_no_name, { Name: "ssm_endpoint" })
}
resource "aws_vpc_endpoint" "ec2messages_endpoint" {
  vpc_id = data.aws_vpc.vpc.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  subnet_ids = var.private_subnet_ids
  private_dns_enabled = true
  vpc_endpoint_type = "Interface"
  security_group_ids = [aws_security_group.ssm_sg.id]

  tags = merge(var.standard_tags_no_name, { Name: "ec2messsages_endpoint" })
}
resource "aws_vpc_endpoint" "ssmmessages_endpoint" {
  vpc_id = data.aws_vpc.vpc.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  subnet_ids = var.private_subnet_ids
  private_dns_enabled = true
  vpc_endpoint_type = "Interface"
  security_group_ids = [aws_security_group.ssm_sg.id]

  tags = merge(var.standard_tags_no_name, { Name: "ssmmesssages_endpoint" })
}

resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile_${data.aws_region.current.name}"
  role = aws_iam_role.role.name

  tags = merge(var.standard_tags_no_name, { Name: "test_profile_${data.aws_region.current.name}" })
}

resource "aws_iam_role" "role" {
  name = "test_role_${data.aws_region.current.name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = merge(var.standard_tags_no_name, { Name: "test_role_${data.aws_region.current.name}" })
}

resource "aws_iam_role_policy_attachment" "attachment" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role = aws_iam_role.role.name
}

#aws ec2 describe-images --region us-east-1 --filter "Name=architecture,Values=arm64" "Name=name,Values=amzn2-ami-hvm-*"
data "aws_ami" "latest_amzn_linux_ami" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "architecture"
    values = ["arm64"]
  }

  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*"]
  }
}

resource "aws_instance" "private_instance" {
  //  ami           = "ami-00315de4391ce4f6d" # us-west-2
  ami           = data.aws_ami.latest_amzn_linux_ami.image_id # us-west-2
  instance_type = "t4g.nano"
  iam_instance_profile = aws_iam_instance_profile.test_profile.name
  vpc_security_group_ids = [aws_security_group.ssm_sg.id]
  subnet_id = var.private_subnet_ids[0]

  credit_specification {
    cpu_credits = "unlimited"
  }

  tags = merge(var.standard_tags_no_name, { Name: "private-instance" })
}

resource "aws_instance" "public_instance" {
  //  ami           = "ami-00315de4391ce4f6d" # us-west-2
  ami           = data.aws_ami.latest_amzn_linux_ami.image_id # us-west-2
  instance_type = "t4g.nano"
  iam_instance_profile = aws_iam_instance_profile.test_profile.name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.ssm_sg.id]
  subnet_id = var.public_subnet_ids[0]

  credit_specification {
    cpu_credits = "unlimited"
  }

  tags = merge(var.standard_tags_no_name, { Name: "public-instance" })
}