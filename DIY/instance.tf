data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]
  name_regex  = "amzn2-ami-hvm*"
}

locals {
  workload_subnets = [
    {
      vpc_id      = module.spoke_vpc_a.vpc_id,
      cidr_blocks = "10.1.0.0/16",
      name        = "spoke_vpc_a_subnet",
      subnet      = module.spoke_vpc_a.all_subnets["subnet_a_workload"]
    },
    {
      vpc_id      = module.spoke_vpc_b.vpc_id,
      cidr_blocks = "10.2.0.0/16",
      name        = "spoke_vpc_b_subnet",
      subnet      = module.spoke_vpc_b.all_subnets["subnet_b_workload"]
    }
  ]
}

## Host Spoke VPC A
resource "aws_security_group" "spoke_vpc_endpoint_sg" {
  for_each    = { for subnet in local.workload_subnets : subnet.name => subnet }
  name        = join("_", [each.value.name, "endpoing_sg"])
  description = "Allow instances to get to SSM Systems Manager"
  vpc_id      = each.value.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [each.value.cidr_blocks]
  }

  tags = {
    Name = join("_", [each.value.name, "endpoing_sg"])
  }
}

resource "aws_security_group" "spoke_vpc_sg" {
  for_each    = { for subnet in local.workload_subnets : subnet.name => subnet }
  name        = join("_", [each.value.name, "sg"])
  description = "ICMP acess from 10.0.0.0/8"
  vpc_id      = each.value.vpc_id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = join("_", [each.value.name, "sg"])
  }
}

resource "aws_vpc_endpoint" "spoke_vpc_ssm_endpoint" {
  for_each            = { for subnet in local.workload_subnets : subnet.name => subnet }
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.spoke_vpc_endpoint_sg[each.value.name].id]
  service_name        = "com.amazonaws.ap-southeast-1.ssm"
  subnet_ids          = [each.value.subnet.id]
  vpc_endpoint_type   = "Interface"
  vpc_id              = each.value.subnet.vpc_id
}

resource "aws_vpc_endpoint" "spoke_vpc_messages_endpoint" {
  for_each            = { for subnet in local.workload_subnets : subnet.name => subnet }
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.spoke_vpc_endpoint_sg[each.value.name].id]
  service_name        = "com.amazonaws.ap-southeast-1.ec2messages"
  subnet_ids          = [each.value.subnet.id]
  vpc_endpoint_type   = "Interface"
  vpc_id              = each.value.subnet.vpc_id
}

resource "aws_vpc_endpoint" "spoke_vpc_ssm_messages_endpoint" {
  for_each            = { for subnet in local.workload_subnets : subnet.name => subnet }
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.spoke_vpc_endpoint_sg[each.value.name].id]
  service_name        = "com.amazonaws.ap-southeast-1.ssmmessages"
  subnet_ids          = [each.value.subnet.id]
  vpc_endpoint_type   = "Interface"
  vpc_id              = each.value.subnet.vpc_id
}

resource "aws_iam_role" "subnet_role" {
  for_each            = { for subnet in local.workload_subnets : subnet.name => subnet }
  name                = join("_", [each.value.name, "role"])
  path                = "/"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"]
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "subnet_instance_profile" {
  for_each = { for subnet in local.workload_subnets : subnet.name => subnet }
  path     = "/"
  role     = aws_iam_role.subnet_role[each.value.name].name
}

resource "aws_instance" "spoke_vpc_host" {
  for_each               = { for subnet in local.workload_subnets : subnet.name => subnet }
  ami                    = data.aws_ami.amazon-linux-2.id
  subnet_id              = each.value.subnet.id
  iam_instance_profile   = aws_iam_instance_profile.subnet_instance_profile[each.value.name].name
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.spoke_vpc_sg[each.value.name].id]

  tags = {
    Name = join("_", [each.value.name, "host"])
  }
}

