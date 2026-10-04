terraform {
  required_version = ">= 1.11"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "region" {
  type    = string
  default = "us-west-2"
}

variable "state_bucket" {
  type        = string
  description = "A globally unique name for the Terraform state bucket"
}

provider "aws" {
  region = var.region
  default_tags {
    tags = { Project = "acme-demo", ManagedBy = "terraform" }
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# Where every environment's Terraform state lives: versioned and never public
resource "aws_s3_bucket" "state" {
  bucket        = var.state_bucket
  force_destroy = true # lab only, so cleanup after the interview is one command
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# The public half of your lab SSH key
resource "aws_key_pair" "lab" {
  key_name   = "acme-lab"
  public_key = file(pathexpand("~/.ssh/acme-lab.pub"))
}

# Runner: nothing can reach it; it calls out to GitHub
resource "aws_security_group" "runner" {
  name   = "acme-runner"
  vpc_id = data.aws_vpc.default.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Web servers: SSH only from the runner; out to the internet for Dynatrace and updates
resource "aws_security_group" "web" {
  name   = "acme-web"
  vpc_id = data.aws_vpc.default.id
  ingress {
    description     = "SSH from the runner only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.runner.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# What the runner may do: browser login (Session Manager), manage EC2, use the state bucket
resource "aws_iam_role" "runner" {
  name = "acme-runner"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "session_manager" {
  role       = aws_iam_role.runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2" {
  role       = aws_iam_role.runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess" # lab only; scope it down at a customer
}

resource "aws_iam_role_policy" "state" {
  name = "terraform-state"
  role = aws_iam_role.runner.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["s3:ListBucket"], Resource = aws_s3_bucket.state.arn },
      { Effect = "Allow", Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"], Resource = "${aws_s3_bucket.state.arn}/*" }
    ]
  })
}

resource "aws_iam_instance_profile" "runner" {
  name = "acme-runner"
  role = aws_iam_role.runner.name
}

resource "aws_instance" "runner" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  vpc_security_group_ids = [aws_security_group.runner.id]
  iam_instance_profile   = aws_iam_instance_profile.runner.name
  root_block_device {
    volume_size = 20
  }
  tags = { Name = "acme-runner" }
  lifecycle {
    ignore_changes = [ami]
  }
}

output "state_bucket" {
  value = aws_s3_bucket.state.bucket
}