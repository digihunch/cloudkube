resource "aws_iam_role" "bastion_instance_role" {
  name = "${var.resource_prefix}-bastion-inst-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Statement1"
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  tags = { Name = "${var.resource_prefix}-Bastion-Instance-Role" }
}

resource "aws_iam_policy" "bastion_cognito_policy" {
  name        = "bastion_cognito_policy"
  description = "Policy to allow bastion role to log on with cognito users."
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cognito-idp:AdminInitiateAuth"
      ],
      "Effect": "Allow",
      "Resource": "${var.cognito_up_arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "bastion_role_policy_attachment" {
  role       = aws_iam_role.bastion_instance_role.name
  policy_arn = aws_iam_policy.bastion_cognito_policy.arn
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "eks_manager_role" {
  name = "${var.resource_prefix}-eks-manager-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Statement1"
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Sid    = "Statement2"
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = ["${data.aws_caller_identity.current.arn}", "${aws_iam_role.bastion_instance_role.arn}"]
        }
      },
    ]
  })
  tags = { Name = "${var.resource_prefix}-EKS-Manager-Role" }
}

resource "aws_iam_policy" "eks_manager_policy" {
  name        = "eks_manager_policy"
  description = "Policy to allow eks manager role to create EKS cluster."
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cloudformation:*",
        "eks:*",
        "iam:*",
        "ec2:*",
        "kms:*",
        "autoscaling:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks_manager_role_policy_attachment" {
  role       = aws_iam_role.eks_manager_role.name
  policy_arn = aws_iam_policy.eks_manager_policy.arn
}
