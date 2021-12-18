resource "aws_key_pair" "runner-pubkey" {
  key_name   = "${var.resource_prefix}-runner-pubkey"
  public_key = var.public_key_data
}

resource "aws_security_group" "bastionsecgrp" {
  name        = "${var.resource_prefix}-cloudkube-sg"
  description = "security group for bastion"
  vpc_id      = data.aws_subnet.mgmt_subnet.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["142.0.0.0/8"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.resource_tags, { Name = "${var.resource_prefix}-BastionSecurityGroup" })
}

resource "aws_iam_role" "ec2_iam_role" {
  name = "${var.resource_prefix}-inst-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags               = var.resource_tags
}

resource "aws_iam_policy" "bastion_eks_policy" {
  name        = "bastion_eks_policy"
  description = "haha"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "eks:Describe*",
        "eks:List*"
      ],
      "Effect": "Allow",
      "Resource": "${var.eks_arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachment" {
  role       = aws_iam_role.ec2_iam_role.name
  policy_arn = aws_iam_policy.bastion_eks_policy.arn
}

resource "aws_iam_instance_profile" "inst_profile" {
  name = "${var.resource_prefix}-inst-profile"
  role = aws_iam_role.ec2_iam_role.name
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  user_data              = data.template_cloudinit_config.bastion_cloudinit.rendered
  key_name               = aws_key_pair.runner-pubkey.key_name
  vpc_security_group_ids = [aws_security_group.bastionsecgrp.id]
  subnet_id              = var.mgmt_subnet_id
  iam_instance_profile   = aws_iam_instance_profile.inst_profile.name
  tags                   = merge(var.resource_tags, { Name = "${var.resource_prefix}-Bastion" })
}

