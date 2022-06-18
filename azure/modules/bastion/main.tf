resource "azurerm_public_ip" "pubip_bastion" {
  name                = "${var.resource_prefix}-pubip-bastion"
  location            = data.azurerm_resource_group.cluster_rg.location
  resource_group_name = data.azurerm_resource_group.cluster_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "bastion_nic" {
  name                = "${var.resource_prefix}-bastion-nic"
  location            = data.azurerm_resource_group.cluster_rg.location
  resource_group_name = data.azurerm_resource_group.cluster_rg.name

  ip_configuration {
    name                          = "${var.resource_prefix}-bstn-nic-cfg"
    subnet_id                     = var.bastion_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pubip_bastion.id
  }
}

# resource type azurerm_bastion_host represents an "Azure Bastion" resource, a fully managed service for connection to VMs. It currently does not support connection to AKS nodes. So it is not what we need. Just use the regular azurerm_virtual_machine for bastion host.
# We place the bastion host in a separate management subnet. In production, the bastion VM should ideally be placed in a separate Vnet with peering to the aks Vnet.
# https://social.msdn.microsoft.com/Forums/azure/en-US/1521d2a9-7b14-494b-bfec-bbc3d2411e3d/why-would-you-need-separate-vnets-when-you-can-segment-by-subnets-within-one-vnet?forum=WAVirtualMachinesVirtualNetwork

resource "azurerm_linux_virtual_machine" "bastion_host" {
  name                  = "${var.resource_prefix}-bastion-host"
  location              = data.azurerm_resource_group.cluster_rg.location
  resource_group_name   = data.azurerm_resource_group.cluster_rg.name
  size                  = "Standard_DS1_v2"
  network_interface_ids = [azurerm_network_interface.bastion_nic.id]
  admin_username        = var.os_user
  os_disk {
    name                 = "${var.resource_prefix}-bstn-dsk001"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  custom_data                     = data.template_cloudinit_config.init_config.rendered
  disable_password_authentication = true
  admin_ssh_key {
    username   = var.os_user
    public_key = var.public_key_data
  }
  tags = var.resource_tags
}
