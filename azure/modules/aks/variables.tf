variable "resource_group" {
  type = string
}
variable "resource_prefix" {
  type = string
}
variable "resource_tags" {
  type = map(any)
}
#variable "aks_kubernetes_version" {
#  type    = string
#  default = "1.21.2"
#}
#variable "aks_ad_admin_group_object_id" {
#  type = list(string)
#}
variable "aks_laws_id" {
  type = string
}
#variable "aks_pod_subnet_id" {
#  type = string
#}
#variable "aks_node_subnet_id" {
#  type = string
#}

variable "aks_spec" {
  description = "AKS specification"
  type = object ({
    cluster_name = string,
    kubernetes_version = string,
    pod_subnet_id = string,
    node_subnet_id = string,
    lb_subnet_id = string,
    admin_group_ad_object_ids = list(string),
    system_node_pool = object({
      name = string,
      vm_size = string,
      zones = list(string),
      node_count = number,
      cluster_auto_scaling = bool,
      cluster_auto_scaling_min_node_count = number,      
      cluster_auto_scaling_max_node_count = number,      
    }),
    workload_node_pools = list(object({
      name = string,
      vm_size = string,
      zones = list(string),
      node_count = number,
      cluster_auto_scaling = bool,
      cluster_auto_scaling_min_node_count = number,      
      cluster_auto_scaling_max_node_count = number,      
    })),
    auto_scaler_profile = object({
      balance_similar_node_groups = bool,
      max_unready_nodes = number,
      scale_down_unready = string,
    })
  })
  default = {
    cluster_name = "default_cluster"
    kubernetes_version = "1.20.1" 
    pod_subnet_id = "unknown"
    node_subnet_id = "unknown"
    lb_subnet_id = "unknown"
    admin_group_ad_object_ids = ["admin_group_object_id"]
    system_node_pool = {
      name = "sysnp"
      vm_size = "Standard_A8_v2"
      zones = ["1","2","3"] 
      node_count = 3
      cluster_auto_scaling = false,
      cluster_auto_scaling_min_node_count = 3,      
      cluster_auto_scaling_max_node_count = 3,      
    }
    workload_node_pools = [{
      name = "wlnp"
      vm_size = "Standard_A8_v2"
      zones = ["1","2","3"]
      node_count = 3
      cluster_auto_scaling = true,
      cluster_auto_scaling_min_node_count = 3,
      cluster_auto_scaling_max_node_count = 9,      
    }]
    auto_scaler_profile = {
      balance_similar_node_groups = false,
      max_unready_nodes = 3,
      scale_down_unready = "20m",
    }
  }
}
