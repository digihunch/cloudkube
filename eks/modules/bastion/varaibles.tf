variable "ssh_pubkey_name" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "bastion_subnet_ids" {
  type = list(any)
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
variable "custom_key_arn" {
  type = string
}
