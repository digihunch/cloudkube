variable "ssh_client_cidr_block" {
  type = string
}
variable "public_key_data" {
  type = string
}
variable "mgmt_subnet_id" {
  type = string
}
variable "eks_name" {
  type = string
}
variable "eks_arn" {
  type = string
}
variable "oidc_provider_app_id" {
  type = string
}
variable "resource_tags" {
  type = map(any)
}
variable "resource_prefix" {
  type = string
}
variable "eks_cluster_kubectl_config" {
  type = map(any)
}
