data "azurerm_resource_group" "default" {
  name = var.resource_group
}

data "template_file" "cloud_init_sh" {
  template = file("${path.module}/files/bastion_init_sh.tpl")
  vars = {
    cluster_fqdn = var.aks_cluster_fqdn
    kube_config  = var.kube_config
    os_user      = var.os_user
  }
}

data "template_cloudinit_config" "init_config" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud-init"
    content_type = "text/x-shellscript"
    content      = data.template_file.cloud_init_sh.rendered
  }
}

