data "azurerm_resource_group" "cluster_rg" {
  name = var.resource_group
}

data "cloudinit_config" "bastion_cloudinit" {
  base64_encode = true
  part {
    filename = "cloud-init"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/files/bastion_init_sh.tpl",{
      cluster_fqdn = var.aks_cluster_fqdn
      kube_config  = var.kube_config
      os_user      = var.os_user
      id_rsa       = var.bastion_id_rsa.private_key_data
      id_rsa_pub   = var.bastion_id_rsa.public_key_data
    })
  }
}
