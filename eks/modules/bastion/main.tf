locals {
  inst_type_bastion   = "t3.medium"
}

resource "aws_security_group" "bastionsecgrp" {
  name        = "${var.resource_prefix}-cloudkube-sg"
  description = "security group for bastion"
  vpc_id      = var.vpc_id 

  egress {
    description = "Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.resource_tags, { Name = "${var.resource_prefix}-BastionSecurityGroup" })
}

resource "aws_iam_policy" "bastion_eks_policy" {
  name        = "${var.resource_prefix}_bastion_eks_policy"
  description = "bastion to allow awscli administrative activities from instance role."
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "eks:Describe*",
        "eks:List*",
        "appmesh:*"
      ],
      "Effect": "Allow",
      "Resource": "${var.eks_arn}"
    },
    {
      "Action": [
        "iam:CreatePolicy",
        "iam:ListPolicies",
        "sts:DecodeAuthorizationMessage"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "bastion_role_eks_policy_attachment" {
  role       = var.bastion_role_name
  policy_arn = aws_iam_policy.bastion_eks_policy.arn
}

resource "aws_iam_role_policy_attachment" "bastion_role_ssm_policy_attachment" {
  role       = var.bastion_role_name 
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "inst_profile" {
  name = "${var.resource_prefix}-inst-profile"
  role = var.bastion_role_name
}

resource "aws_launch_template" "bastion_launch_template" {
  name          = "${var.resource_prefix}-bastion-launch-template"
  key_name      = var.ssh_pubkey_name 
  instance_type = local.inst_type_bastion
  user_data     = data.cloudinit_config.bastion_cloudinit.rendered 
  image_id      = data.aws_ami.amazon_linux.id
  ebs_optimized = true
  iam_instance_profile {
    name = aws_iam_instance_profile.inst_profile.name
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      encrypted   = true
      kms_key_id = var.custom_key_arn
    }
  }
  vpc_security_group_ids = [aws_security_group.bastionsecgrp.id]#
  tag_specifications {
    resource_type = "instance"
    tags = {
      prefix = var.resource_prefix
      purpose = "bastion"
      Name = "${var.resource_prefix}-bastion"
    }
  }
}

resource "aws_autoscaling_group" "bastion_host_asg" {
  vpc_zone_identifier = var.bastion_subnet_ids 
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1
  name = "${var.resource_prefix}-bastion-asg" 

  launch_template {
    id      = aws_launch_template.bastion_launch_template.id
    version = aws_launch_template.bastion_launch_template.latest_version 
  }
}
