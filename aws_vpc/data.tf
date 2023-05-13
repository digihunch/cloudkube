data "aws_region" "this" {}

data "aws_availability_zones" "this" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023**"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_instances" "bastion" {
  instance_tags = {
    purpose = "bastion"
    prefix = var.resource_prefix
    Name = "${var.resource_prefix}-bastion"
  }
  depends_on = [aws_autoscaling_group.bastion_host_asg]
}

data "cloudinit_config" "bastion_cloudinit" {
  base64_encode = true
  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/myuserdata.tpl", {
      aws_region                  = data.aws_region.this.name
    })
  }
}
