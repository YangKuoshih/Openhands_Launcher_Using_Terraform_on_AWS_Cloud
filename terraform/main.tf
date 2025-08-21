###############################
# TERRAFORM & PROVIDER CONFIG
###############################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = local.config.aws.region
}

###############################
# DATA SOURCES
###############################
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

data "http" "current_ip" {
  url = "https://api.ipify.org"
  request_headers = {
    Accept = "application/text"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

###############################
# LOCAL VARIABLES
###############################
locals {
  config = jsondecode(file("${path.module}/config.json"))
  common_tags = {
    Project   = local.config.project.id
    Name      = local.config.project.name
    Owner     = local.config.project.owner
    CreatedBy = "terraform"
  }
  current_ip = "${chomp(data.http.current_ip.response_body)}/32"
  # Allow additional IPs if specified in config, otherwise just current IP
  allowed_ips = try(local.config.security.allowed_source_ips, [])
  all_allowed_ips = concat(local.allowed_ips, [local.current_ip])
}

###############################
# NETWORKING: VPC, SUBNET, IGW, ROUTE TABLE
###############################
resource "aws_vpc" "main" {
  cidr_block           = local.config.network.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.config.project.id}-vpc"
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.config.network.public_subnet_cidr
  availability_zone       = local.config.aws.availability_zone
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.config.project.id}-public-subnet"
  })

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.config.network.private_subnet_cidr
  availability_zone = local.config.aws.availability_zone

  tags = merge(local.common_tags, {
    Name = "${local.config.project.id}-private-subnet"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.config.project.id}-igw"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.config.project.id}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

###############################
# SECURITY GROUP
###############################
resource "aws_security_group" "openhands" {
  name        = "${local.config.project.id}_allow_sources"
  description = "Allow SSH and OpenHands inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from allowed sources"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.all_allowed_ips
  }

  ingress {
    description = "OpenHands web access"
    from_port   = 8150
    to_port     = 8150
    protocol    = "tcp"
    cidr_blocks = local.all_allowed_ips
  }

  ingress {
    description = "VS Code integration ports"
    from_port   = 30000
    to_port     = 60000
    protocol    = "tcp"
    cidr_blocks = local.all_allowed_ips
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.config.project.id}_allow_sources"
  })

  lifecycle {
    create_before_destroy = false
  }
}

###############################
# IAM ROLES & INSTANCE PROFILE
###############################
resource "aws_iam_role" "openhands_role" {
  name = "${local.config.project.id}-openhands-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${local.config.project.id}-openhands-role"
  })
}

resource "aws_iam_policy" "openhands_policy" {
  name        = "${local.config.project.id}-openhands-policy"
  description = "Policy for OpenHands EC2 instance"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "bedrock:*",
        "s3:GetObject",
        "s3:PutObject",
        "ssm:GetParameter",
        "ssm:GetParameters"
      ],
      Resource = "*"
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${local.config.project.id}-openhands-policy"
  })
}

resource "aws_iam_role_policy_attachment" "attach_openhands_policy" {
  policy_arn = aws_iam_policy.openhands_policy.arn
  role       = aws_iam_role.openhands_role.name
}

resource "aws_iam_instance_profile" "openhands_profile" {
  name = "${local.config.project.id}-instance-profile"
  role = aws_iam_role.openhands_role.name

  tags = merge(local.common_tags, {
    Name = "${local.config.project.id}-instance-profile"
  })
}

###############################
# KEY PAIR & TLS PRIVATE KEY
###############################
resource "tls_private_key" "openhands" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "null_resource" "create_keys_dir" {
  provisioner "local-exec" {
    command = "if not exist keys mkdir keys"
    interpreter = ["cmd", "/C"]
  }
}

resource "local_file" "private_key" {
  content         = tls_private_key.openhands.private_key_pem
  filename        = "${path.module}/keys/openhands-key.pem"
  file_permission = "0600"
  depends_on      = [null_resource.create_keys_dir]
}

resource "local_file" "public_key" {
  content    = tls_private_key.openhands.public_key_openssh
  filename   = "${path.module}/keys/openhands-key.pub"
  depends_on = [null_resource.create_keys_dir]
}

resource "aws_key_pair" "openhands" {
  key_name   = local.config.aws.key_name
  public_key = tls_private_key.openhands.public_key_openssh
  
  tags = merge(local.common_tags, {
    Name = "${local.config.project.id}-key-pair"
  })
}

###############################
# EC2 INSTANCE
###############################
resource "aws_instance" "openhands" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = local.config.aws.instance_type
  key_name                    = aws_key_pair.openhands.key_name
  iam_instance_profile        = aws_iam_instance_profile.openhands_profile.name
  vpc_security_group_ids      = [aws_security_group.openhands.id]
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  user_data                   = file("${path.module}/user-data.sh")

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
  }

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = merge(local.common_tags, {
    Name          = "${local.config.project.id}-instance"
    AutoStopStart = "True"
  })

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_eip" "openhands_eip" {
  instance = aws_instance.openhands.id
  
  tags = merge(local.common_tags, {
    Name = "${local.config.project.id}-eip"
  })
}

###############################
# SCHEDULER & INSTANCE AUTO STOP/START
###############################
data "aws_instances" "tagged_instances" {
  filter {
    name   = "tag:AutoStopStart"
    values = ["True"]
  }
  depends_on = [aws_instance.openhands]
}

resource "aws_iam_role" "scheduler_role" {
  name = "${local.config.project.id}-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "scheduler.amazonaws.com" }
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${local.config.project.id}-scheduler-role"
  })
}

resource "aws_iam_role_policy" "scheduler_policy" {
  name = "${local.config.project.id}-scheduler-policy"
  role = aws_iam_role.scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "ec2:StartInstances",
        "ec2:StopInstances"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_scheduler_schedule" "stop_ec2" {
  name       = "${local.config.project.id}-stop-schedule"
  group_name = "default"
  flexible_time_window { mode = "OFF" }
  schedule_expression = local.config.schedule.stop_time
  
  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.scheduler_role.arn
    input    = jsonencode({ InstanceIds = data.aws_instances.tagged_instances.ids })
  }
}

resource "aws_scheduler_schedule" "start_ec2" {
  name       = "${local.config.project.id}-start-schedule"
  group_name = "default"
  state      = "ENABLED"
  flexible_time_window { mode = "OFF" }
  schedule_expression = local.config.schedule.start_time
  
  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = aws_iam_role.scheduler_role.arn
    input    = jsonencode({ InstanceIds = data.aws_instances.tagged_instances.ids })
  }
}

###############################
# SSM PARAMETERS
###############################
resource "aws_ssm_parameter" "openhands_info" {
  name = "/${local.config.project.id}/info"
  type = "String"
  value = jsonencode({
    elasticIP      = aws_eip.openhands_eip.public_ip,
    projectId      = local.config.project.id,
    instanceId     = aws_instance.openhands.id,
    securityGroupId = aws_security_group.openhands.id,
    ec2PublicDns   = aws_instance.openhands.public_dns,
    eipPublicDns   = aws_eip.openhands_eip.public_dns
  })

  tags = merge(local.common_tags, {
    Name = "${local.config.project.id}-info"
  })

  depends_on = [
    aws_eip.openhands_eip,
    aws_instance.openhands
  ]
}

###############################
# LOCAL OUTPUT FILES
###############################
resource "local_file" "env_vars" {
  filename = "${path.module}/set-env-vars.bat"
  content = <<-EOT
    set AWS_REGION=${data.aws_region.current.name}
    set ELASTIC_IP=${aws_eip.openhands_eip.public_ip}
    set PROJECT_ID=${local.config.project.id}
    set INSTANCE_ID=${aws_instance.openhands.id}
    set PUBLIC_DNS=${aws_eip.openhands_eip.public_dns}
    set SECURITY_GROUP_ID=${aws_security_group.openhands.id}
    set OPENHANDS_URL=http://${aws_eip.openhands_eip.public_dns}:${local.config.openhands.port}
  EOT
  
  depends_on = [aws_eip.openhands_eip]
}