variable "resource_group" {
  type = string
}
variable "resource_location" {
  type = string
}
variable "resource_prefix" {
  type = string
}
variable "resource_tags" {
  type = map(any)
}
variable "ssh_client_cidr_block" {
  type = string
}
