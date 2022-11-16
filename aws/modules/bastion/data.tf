data "aws_region" "this" {}
data "aws_iam_role" "eks_manager_role" {
  name = var.eks_manager_role_name
}

data "aws_subnet" "mgmt_subnet" {
  id = var.mgmt_subnet_id
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
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

data "template_file" "myuserdata" {
  template = file("${path.module}/myuserdata.tpl")
  vars = {
    aws_region = data.aws_region.this.name
    eks_name = var.eks_name
    eks_cluster_arn = var.eks_arn
    eks_manager_role_arn = data.aws_iam_role.eks_manager_role.arn
    cognito_oidc_issuer_url = var.cognito_oidc_issuer_url
    cognito_user_pool_id = var.cognito_user_pool_id
    cognito_oidc_client_id = var.cognito_oidc_client_id
    cluster_admin_cognito_group = var.cluster_admin_cognito_group
  }
}

data "template_cloudinit_config" "bastion_cloudinit" {
  base64_encode = true
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.myuserdata.rendered
  }
  part {
    content_type = "text/x-shellscript"
    content      = file("${path.module}/custom_userdata.sh")
  }
}
