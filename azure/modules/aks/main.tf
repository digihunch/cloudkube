resource "azurerm_user_assigned_identity" "default" {
  name                = "${var.resource_prefix}-aks-user-identity"
  location            = data.azurerm_resource_group.default.location
  resource_group_name = data.azurerm_resource_group.default.name
  tags                = var.resource_tags
}

resource "azurerm_kubernetes_cluster" "default" {
  location                            = data.azurerm_resource_group.default.location
  resource_group_name                 = data.azurerm_resource_group.default.name
  name                                = "${var.resource_prefix}-${var.aks_spec.cluster_name}"
  dns_prefix                          = "${var.resource_prefix}-k8s"
  kubernetes_version                  = var.aks_spec.kubernetes_version
  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = true

  default_node_pool {
    name                = var.aks_spec.system_node_pool.name
    type                = "VirtualMachineScaleSets"
    node_count          = var.aks_spec.system_node_pool.node_count
    enable_auto_scaling = var.aks_spec.system_node_pool.cluster_auto_scaling
    min_count           = var.aks_spec.system_node_pool.cluster_auto_scaling ? var.aks_spec.system_node_pool.cluster_auto_scaling_min_node_count : null
    max_count           = var.aks_spec.system_node_pool.cluster_auto_scaling ? var.aks_spec.system_node_pool.cluster_auto_scaling_max_node_count : null
    vm_size             = var.aks_spec.system_node_pool.vm_size
    os_disk_size_gb     = 30
    pod_subnet_id       = var.aks_spec.pod_subnet_id
    # https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni#install-the-aks-preview-azure-cli
    vnet_subnet_id     = var.aks_spec.node_subnet_id
    availability_zones = var.aks_spec.system_node_pool.zones
    # https://docs.microsoft.com/en-us/azure/aks/availability-zones#verify-node-distribution-across-zones
  }

  identity {
    type                      = "SystemAssigned"
    user_assigned_identity_id = azurerm_user_assigned_identity.default.id
  }

  role_based_access_control {
    enabled = true
    azure_active_directory {
      managed                = true
      azure_rbac_enabled     = true
      admin_group_object_ids = var.aks_spec.admin_group_ad_object_ids
    }
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
    #outbound_type = "userDefinedRouting" # UDR requires firewall IP. 
  }
  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = var.aks_laws_id
    }
    # kube_dashboard is deprecated starting 1.19
    azure_policy {
      enabled = true
    }
  }

  auto_scaler_profile {
    scan_interval       = "60s"
    scale_down_unneeded = "10m"
  }
  tags = var.resource_tags
}

resource "azurerm_kubernetes_cluster_node_pool" "workload_node_pool" {
  for_each              = { for node_pool in var.aks_spec.workload_node_pools : node_pool.name => node_pool }
  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.default.id
  pod_subnet_id         = var.aks_spec.pod_subnet_id
  vnet_subnet_id        = var.aks_spec.node_subnet_id
  vm_size               = each.value.vm_size
  availability_zones    = each.value.zones
  node_count            = each.value.node_count
  enable_auto_scaling   = each.value.cluster_auto_scaling
  max_count             = each.value.cluster_auto_scaling ? each.value.cluster_auto_scaling_max_node_count : null
  min_count             = each.value.cluster_auto_scaling ? each.value.cluster_auto_scaling_min_node_count : null
  #proximity_placement_group_id = azurerm_proximity_placement_group.default.id # placement group can map to only one AZ 
  # enable_host_encryption = true # this is not supported for certain instance types
  mode = "User"
  tags = var.resource_tags
}
