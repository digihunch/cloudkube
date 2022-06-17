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
  node_resource_group                 = "${data.azurerm_resource_group.default.name}-${var.resource_prefix}-${var.aks_spec.cluster_name}-node"

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
    vnet_subnet_id = var.aks_spec.node_subnet_id

    availability_zones = var.aks_spec.system_node_pool.zones
    # https://docs.microsoft.com/en-us/azure/aks/availability-zones#verify-node-distribution-across-zones
    node_labels = var.aks_spec.system_node_pool.node_labels
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
    #outbound_type = "userDefinedRouting" # UDR requires presence of a route for subnet pointing to firewall IP. 
  }
  addon_profile {
    oms_agent {
      enabled                    = var.aks_spec.laws_id != null
      log_analytics_workspace_id = var.aks_spec.laws_id
    }
    # kube_dashboard is deprecated starting 1.19
    azure_policy {
      enabled = true
    }
    ingress_application_gateway {
      enabled = false
    }
    http_application_routing {
      enabled = false
    }
  }
  linux_profile {
    admin_username = var.aks_spec.node_os_user 
    ssh_key {
      key_data = var.aks_spec.node_public_key
    }
  }

  auto_scaler_profile {
    balance_similar_node_groups      = var.aks_spec.auto_scaler_profile.balance_similar_node_groups
    expander                         = var.aks_spec.auto_scaler_profile.expander
    max_graceful_termination_sec     = var.aks_spec.auto_scaler_profile.max_graceful_termination_sec
    max_node_provisioning_time       = var.aks_spec.auto_scaler_profile.max_node_provisioning_time
    max_unready_nodes                = var.aks_spec.auto_scaler_profile.max_unready_nodes
    max_unready_percentage           = var.aks_spec.auto_scaler_profile.max_unready_percentage
    new_pod_scale_up_delay           = var.aks_spec.auto_scaler_profile.new_pod_scale_up_delay
    scale_down_delay_after_add       = var.aks_spec.auto_scaler_profile.scale_down_delay_after_add
    scale_down_delay_after_delete    = var.aks_spec.auto_scaler_profile.scale_down_delay_after_delete
    scale_down_delay_after_failure   = var.aks_spec.auto_scaler_profile.scale_down_delay_after_failure
    scan_interval                    = var.aks_spec.auto_scaler_profile.scan_interval
    scale_down_unneeded              = var.aks_spec.auto_scaler_profile.scale_down_unneeded
    scale_down_unready               = var.aks_spec.auto_scaler_profile.scale_down_unready
    scale_down_utilization_threshold = var.aks_spec.auto_scaler_profile.scale_down_utilization_threshold
    empty_bulk_delete_max            = var.aks_spec.auto_scaler_profile.empty_bulk_delete_max
    skip_nodes_with_local_storage    = var.aks_spec.auto_scaler_profile.skip_nodes_with_local_storage
    skip_nodes_with_system_pods      = var.aks_spec.auto_scaler_profile.skip_nodes_with_system_pods
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
  # proximity_placement_group_id = azurerm_proximity_placement_group.default.id # placement group can map to only one AZ 
  # enable_host_encryption = true # feature needs to be enabled https://docs.microsoft.com/en-us/azure/aks/enable-host-encryption
  mode        = "User"
  node_labels = each.value.node_labels
  tags        = var.resource_tags
}
