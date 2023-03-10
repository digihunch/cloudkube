variable "node_subnet_ids" {
  type = list(any)
}
variable "vpc_id" {
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
variable "include_arm64_nodegroup" {
  type = bool
}
variable "resource_tags" {
  type = map(any)
}
variable "resource_prefix" {
  type = string
}
