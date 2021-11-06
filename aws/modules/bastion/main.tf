resource "aws_key_pair" "runner-pubkey" {
  key_name   = "runner-pubkey"
  public_key = var.public_key_data 
}

resource "aws_security_group" "bastionsecgrp" {
  name        = "bastion_sg"
  description = "security group for bastion"
  vpc_id      = data.aws_subnet.mgmt_subnet.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.resource_tags,{ Name="Bastion" })
}

resource "aws_iam_instance_profile" "inst_profile" {
  name = "inst_profile"
  role = data.aws_iam_role.instance_role.name
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  user_data              = data.template_cloudinit_config.bastion_cloudinit.rendered
  key_name               = aws_key_pair.runner-pubkey.key_name 
  vpc_security_group_ids = [aws_security_group.bastionsecgrp.id]
  subnet_id              = var.mgmt_subnet_id
  iam_instance_profile   = aws_iam_instance_profile.inst_profile.name
  tags = merge(var.resource_tags,{ Name="Bastion" })
}

