variable "resource_group" {
  type = string
}
variable "resource_prefix" {
  type = string
}
variable "resource_tags" {
  type = map(any)
}
variable "aks_cluster_fqdn" {
  type = string
}
variable "kube_config" {
  type = string
}
variable "bastion_subnet_id" {
  type = string
}
variable "public_key_data" {
  type = string
}
variable "os_user" {
  type    = string
  default = "kubeadmin"
}
