# we use locals instead of variables because variable default cannot reference another variable.
locals {
  default_cidrs = {
    vnet_cidr        = "10.0.0.0/8"
    node_subnet_cidr = "10.1.0.0/16"
    pod_subnet_cidr  = "10.2.0.0/16"
    mgmt_subnet_cidr = "10.3.0.0/16"
  }
  node_sec_rules = [{
    name                       = "NodeSubnetNetworkSecurityGroupRule01"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = local.default_cidrs.mgmt_subnet_cidr
    destination_address_prefix = "*"
    }, {
    name                       = "NodeSubnetNetworkSecurityGroupRule02"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = local.default_cidrs.mgmt_subnet_cidr
    destination_address_prefix = "*"
  }]
  pod_sec_rules = [{
    name                       = "PodSubnetNetworkSecurityGroupRule01"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = local.default_cidrs.vnet_cidr
    destination_address_prefix = "*"
    }, {
    name                       = "PodSubnetNetworkSecurityGroupRule02"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = local.default_cidrs.vnet_cidr
    destination_address_prefix = "*"
  }]
}
