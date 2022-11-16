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
variable "cognito_oidc_issuer_url" {
  type = string
}
variable "cognito_user_pool_id" {
  type = string
}
variable "cognito_oidc_client_id" {
  type = string
}
variable "resource_tags" {
  type = map(any)
}
variable "resource_prefix" {
  type = string
}
variable "bastion_role_name" {
  type = string
}
variable "eks_manager_role_name" {
  type = string
}
variable "cluster_admin_cognito_group" {
  type = string
}
