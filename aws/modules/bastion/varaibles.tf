variable "public_key_data" {
  type = string
}
variable "mgmt_subnet_id" {
  type = string
}
variable "eks_name" {
  type = string
}
#variable "eks_arn" {
#  type = string
#}
variable "eks_endpoint" {
  type = string
}
variable "eks_config_certificate" {
  type = string
}
variable "eks_tls_certificate" {
  type = string
}
variable "eks_node_role_name" {
  type = string
}
variable "resource_tags" {
  type = map(any)
}
variable "resource_prefix" {
  type = string
}
