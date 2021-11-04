output "username" {
  value = var.os_user
}
output "host" {
  value = azurerm_public_ip.pubip_bastion.ip_address
}
