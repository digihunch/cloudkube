#resource "aws_key_pair" "runner-pubkey" {
#  key_name   = "${var.resource_prefix}-runner-pubkey"
#  public_key = var.public_key_data
#}

resource "aws_security_group" "bastionsecgrp" {
  name        = "${var.resource_prefix}-cloudkube-sg"
  description = "security group for bastion"
  vpc_id      = data.aws_subnet.mgmt_subnet.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_client_cidr_block]
  }
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
  name        = "bastion_eks_policy"
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

resource "aws_iam_instance_profile" "inst_profile" {
  name = "${var.resource_prefix}-inst-profile"
  role = var.bastion_role_name
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.medium"
  user_data              = data.cloudinit_config.bastion_cloudinit.rendered
  key_name               = var.ssh_pubkey_name 
  vpc_security_group_ids = [aws_security_group.bastionsecgrp.id]
  subnet_id              = var.mgmt_subnet_id
  iam_instance_profile   = aws_iam_instance_profile.inst_profile.name
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }
  root_block_device {
    encrypted  = true
    kms_key_id = var.custom_key_arn
  }
  ebs_optimized = true
  tags          = merge(var.resource_tags, { Name = "${var.resource_prefix}-Bastion" })
}

