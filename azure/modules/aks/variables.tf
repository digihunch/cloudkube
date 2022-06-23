variable "resource_group" {
  type = string
}
variable "resource_location" {
  type = string
}
variable "resource_prefix" {
  type = string
}
variable "resource_tags" {
  type = map(any)
}
variable "aks_byo_mi" {
  type = object({
    id           = string,
    client_id    = string,
    principal_id = string,
  })
}
variable "aks_spec" {
  description = "AKS specification"
  type = object({
    cluster_name              = string,
    kubernetes_version        = string,
    pod_subnet_id             = string,
    node_subnet_id            = string,
    laws_id                   = string,
    node_os_user              = string,
    node_public_key           = string,
    admin_group_ad_object_ids = list(string),
    system_node_pool = object({
      name                                = string,
      vm_size                             = string,
      zones                               = list(string),
      node_count                          = number,
      cluster_auto_scaling                = bool,
      cluster_auto_scaling_min_node_count = number,
      cluster_auto_scaling_max_node_count = number,
      node_labels                         = map(any),
      node_taints                         = list(string),
    }),
    workload_node_pools = list(object({
      name                                = string,
      vm_size                             = string,
      zones                               = list(string),
      node_count                          = number,
      cluster_auto_scaling                = bool,
      cluster_auto_scaling_min_node_count = number,
      cluster_auto_scaling_max_node_count = number,
      node_labels                         = map(any),
      node_taints                         = list(string),
    })),
    auto_scaler_profile = object({
      balance_similar_node_groups      = bool,
      expander                         = string,
      max_graceful_termination_sec     = number,
      max_node_provisioning_time       = string,
      max_unready_nodes                = number,
      max_unready_percentage           = number,
      new_pod_scale_up_delay           = string,
      scale_down_delay_after_add       = string,
      scale_down_delay_after_delete    = string,
      scale_down_delay_after_failure   = string,
      scan_interval                    = string,
      scale_down_unneeded              = string,
      scale_down_unready               = string,
      scale_down_utilization_threshold = number,
      empty_bulk_delete_max            = number,
      skip_nodes_with_local_storage    = bool,
      skip_nodes_with_system_pods      = bool,
    })
  })
  default = {
    cluster_name              = "default_cluster"
    kubernetes_version        = "1.23.3"
    pod_subnet_id             = "unknown"
    node_subnet_id            = "unknown"
    laws_id                   = "unknown"
    node_os_user              = "kubeadmin"
    node_public_key           = ""
    admin_group_ad_object_ids = ["admin_group_object_id"]
    system_node_pool = {
      name                                = "sysnp"
      vm_size                             = "Standard_D2s_v4"
      zones                               = ["1", "2", "3"]
      node_count                          = 3
      cluster_auto_scaling                = false,
      cluster_auto_scaling_min_node_count = 3,
      cluster_auto_scaling_max_node_count = 3,
      node_labels = {
        pool_name = "sysnp00"
      },
      node_taints = null,
    }
    workload_node_pools = [{
      name                                = "wlnp"
      vm_size                             = "Standard_D2s_v4"
      zones                               = ["1", "2", "3"]
      node_count                          = 3
      cluster_auto_scaling                = true,
      cluster_auto_scaling_min_node_count = 3,
      cluster_auto_scaling_max_node_count = 9,
      node_labels = {
        pool_name = "nodenp01"
      },
      node_taints = null,
    }]
    auto_scaler_profile = {
      balance_similar_node_groups      = false,
      expander                         = "random",
      max_graceful_termination_sec     = 600,
      max_node_provisioning_time       = "15m",
      max_unready_nodes                = 3,
      max_unready_percentage           = 45,
      new_pod_scale_up_delay           = "10s",
      scale_down_delay_after_add       = "10m",
      scale_down_delay_after_delete    = "10s",
      scale_down_delay_after_failure   = "3m",
      scan_interval                    = "10s",
      scale_down_unneeded              = "10m",
      scale_down_unready               = "20m",
      scale_down_utilization_threshold = 0.5,
      empty_bulk_delete_max            = 10,
      skip_nodes_with_local_storage    = true,
      skip_nodes_with_system_pods      = true,
    }
  }
}
