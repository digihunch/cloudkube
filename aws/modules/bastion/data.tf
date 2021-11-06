data "aws_region" "this" {}

data "aws_iam_role" "instance_role" {
  name = var.role_name
}

data "aws_subnet" "mgmt_subnet" {
  id = var.mgmt_subnet_id
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = [ "amazon" ]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

data "template_file" "myuserdata" {
  template = file("${path.module}/myuserdata.tpl")
  vars = {
    aws_region  = data.aws_region.this.name 
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
