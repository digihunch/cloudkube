resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_prefix}-vnet"
  address_space       = [local.default_cidrs.vnet_cidr]
  location            = data.azurerm_resource_group.cluster_rg.location
  resource_group_name = data.azurerm_resource_group.cluster_rg.name
  tags                = var.resource_tags
}

# to use load balancer subnet, annotate Service object accordingly
# https://docs.microsoft.com/en-us/azure/aks/internal-lb#specify-a-different-subnet
resource "azurerm_subnet" "lb_subnet" {
  name                 = "${var.resource_prefix}-lb-subnet"
  resource_group_name  = data.azurerm_resource_group.cluster_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [local.default_cidrs.lb_subnet_cidr]
}

resource "azurerm_subnet" "node_subnet" {
  name                 = "${var.resource_prefix}-node-subnet"
  resource_group_name  = data.azurerm_resource_group.cluster_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [local.default_cidrs.node_subnet_cidr]
}

resource "azurerm_subnet" "pod_subnet" {
  name                 = "${var.resource_prefix}-pod-subnet"
  resource_group_name  = data.azurerm_resource_group.cluster_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [local.default_cidrs.pod_subnet_cidr]
}

resource "azurerm_subnet" "mgmt_subnet" {
  name                 = "${var.resource_prefix}-mgmt-subnet"
  resource_group_name  = data.azurerm_resource_group.cluster_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [local.default_cidrs.mgmt_subnet_cidr]
}

resource "azurerm_network_security_group" "lb_nsg" {
  name                = "${var.resource_prefix}-lb-nsg"
  location            = data.azurerm_resource_group.cluster_rg.location
  resource_group_name = data.azurerm_resource_group.cluster_rg.name

  dynamic "security_rule" {
    for_each = local.lb_sec_rules
    content {
      name                       = security_rule.value["name"]
      priority                   = security_rule.value["priority"]
      direction                  = security_rule.value["direction"]
      access                     = security_rule.value["access"]
      protocol                   = security_rule.value["protocol"]
      source_port_range          = security_rule.value["source_port_range"]
      destination_port_range     = security_rule.value["destination_port_range"]
      source_address_prefix      = security_rule.value["source_address_prefix"]
      destination_address_prefix = security_rule.value["destination_address_prefix"]
    }
  }
  tags = var.resource_tags
}

resource "azurerm_network_security_group" "node_nsg" {
  name                = "${var.resource_prefix}-node-nsg"
  location            = data.azurerm_resource_group.cluster_rg.location
  resource_group_name = data.azurerm_resource_group.cluster_rg.name

  dynamic "security_rule" {
    for_each = local.node_sec_rules
    content {
      name                       = security_rule.value["name"]
      priority                   = security_rule.value["priority"]
      direction                  = security_rule.value["direction"]
      access                     = security_rule.value["access"]
      protocol                   = security_rule.value["protocol"]
      source_port_range          = security_rule.value["source_port_range"]
      destination_port_range     = security_rule.value["destination_port_range"]
      source_address_prefix      = security_rule.value["source_address_prefix"]
      destination_address_prefix = security_rule.value["destination_address_prefix"]
    }
  }
  tags = var.resource_tags
}

resource "azurerm_network_security_group" "pod_nsg" {
  name                = "${var.resource_prefix}-pod-nsg"
  location            = data.azurerm_resource_group.cluster_rg.location
  resource_group_name = data.azurerm_resource_group.cluster_rg.name

  dynamic "security_rule" {
    for_each = local.pod_sec_rules
    content {
      name                       = security_rule.value["name"]
      priority                   = security_rule.value["priority"]
      direction                  = security_rule.value["direction"]
      access                     = security_rule.value["access"]
      protocol                   = security_rule.value["protocol"]
      source_port_range          = security_rule.value["source_port_range"]
      destination_port_range     = security_rule.value["destination_port_range"]
      source_address_prefix      = security_rule.value["source_address_prefix"]
      destination_address_prefix = security_rule.value["destination_address_prefix"]
    }
  }
  tags = var.resource_tags
}

resource "azurerm_network_security_group" "mgmt_nsg" {
  name                = "${var.resource_prefix}-management-nsg"
  location            = data.azurerm_resource_group.cluster_rg.location
  resource_group_name = data.azurerm_resource_group.cluster_rg.name
  # inline rule is sufficient for management subnet
  security_rule {
    name                       = "AllowSSHFromSpecificCidrs"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = [local.default_cidrs.vnet_cidr, var.ssh_client_cidr_block]
    destination_address_prefix = "*"
  }
  tags = var.resource_tags
}

resource "azurerm_subnet_network_security_group_association" "node_subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.node_subnet.id
  network_security_group_id = azurerm_network_security_group.node_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "pod_subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.pod_subnet.id
  network_security_group_id = azurerm_network_security_group.pod_nsg.id
}
resource "azurerm_subnet_network_security_group_association" "mgmt_subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.mgmt_subnet.id
  network_security_group_id = azurerm_network_security_group.mgmt_nsg.id
}

