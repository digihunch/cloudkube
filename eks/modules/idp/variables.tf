variable "init_admin_email" {
  type = string
}
variable "resource_prefix" {
  type = string
}
variable "resource_tags" {
  type = map(any)
}
variable "cluster_admin_cognito_group" {
  type = string
}
