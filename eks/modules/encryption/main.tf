resource "aws_key_pair" "ssh-pubkey" {
  key_name   = "${var.resource_prefix}-ssh-pubkey"
  public_key = var.ssh_pubkey_data
}

data "aws_caller_identity" "current" {}
data "aws_region" "this" {}

resource "aws_kms_key" "customKey" {
  description             = "This key is used to encrypt resources"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  ## For the key policy to be valid, it requires a service-linked role AWSServiceRoleForAutoScaling to be present. This service-linked role can be created automatically for the first time you create an ASG. 
  # https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-service-linked-role.html#create-service-linked-role
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS":"arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": [
        "kms:*"
      ],
      "Resource": "*"
    },{
      "Sid": "Allow Cloud Watch, VPC flow log and s3 access logging sources to use the key",
      "Effect": "Allow",
      "Principal": {
        "AWS":"arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
        "Service": [
          "logs.${data.aws_region.this.name}.amazonaws.com",
          "delivery.logs.amazonaws.com",
          "logging.s3.amazonaws.com"
        ]
      },
      "Action": [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ],
      "Resource": "*"
    },{
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS":"arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
      },
      "Action": [
        "kms:CreateGrant"
      ],
      "Resource": "*",
      "Condition": {
        "Bool": {
          "kms:GrantIsForAWSResource": "true"
        }
      }
    }
  ]
}
EOF
  tags   = { Name = "${var.resource_prefix}-Custom-KMS-Key" }
}


