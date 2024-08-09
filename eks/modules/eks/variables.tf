variable "node_subnet_ids" {
  type = list(any)
}
variable "vpc_id" {
  type = string
}
variable "ssh_pubkey_name" {
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
variable "custom_key_arn" {
  type = string
}
variable "node_group_configs" {
  type = list(map(any))
}
variable "kubernetes_version" {
  type = string
}
variable "resource_prefix" {
  type = string
}
