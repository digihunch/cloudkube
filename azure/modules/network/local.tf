# we use locals instead of variables because variable default cannot reference another variable.
locals {
  default_cidrs = {
    vnet_cidr        = "147.206.0.0/16"
    lb_subnet_cidr   = "147.206.1.0/24"
    node_subnet_cidr = "147.206.2.0/24"
    pod_subnet_cidr  = "147.206.3.0/24"
    mgmt_subnet_cidr = "147.206.4.0/24"
  }
  lb_sec_rules = [{
    name                       = "LoadBalancerSubnetNetworkSecurityGroupRule01"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    }, {
    name                       = "LoadBalancerSubnetNetworkSecurityGroupRule02"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }]
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
