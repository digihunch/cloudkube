variable "resource_group" {
  type = string
}
variable "resource_prefix" {
  type = string
}
variable "resource_tags" {
  type = map(any)
}
variable "aks_kubernetes_version" {
  type    = string
  default = "1.21.2"
}
variable "aks_network_plugin" {
  type = string
}
variable "aks_ad_admin_group_object_id" {
  type = list(string)
}
variable "aks_laws_id" {
  type = string
}
variable "aks_pod_subnet_id" {
  type = string
}
variable "aks_node_subnet_id" {
  type = string
}
