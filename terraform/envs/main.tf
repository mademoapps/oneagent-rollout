data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

data "aws_security_group" "web" {
  name = "acme-web" # from bootstrap: SSH only from the runner
}

resource "aws_instance" "web" {
  count                  = var.instance_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = "acme-lab"
  vpc_security_group_ids = [data.aws_security_group.web.id]
  user_data              = file("${path.module}/web-cloud-init.yaml")

  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = format("%s-web-%02d", var.environment, count.index + 1)
    Role = "web"
  }

  lifecycle {
    ignore_changes = [ami] # a newer Ubuntu image must never replace running servers
  }
}

output "servers" {
  value = aws_instance.web[*].tags.Name
}