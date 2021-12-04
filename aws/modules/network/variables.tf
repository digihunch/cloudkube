variable "vpc_cidr_block" {
  type = string
}
variable "mgmt_subnet_cidr_block" {
  type = string
}
variable "node_subnet1_cidr_block" {
  type = string
}
variable "node_subnet2_cidr_block" {
  type = string
}
variable "pod_subnet_cidr_block" {
  type = string
}
variable "resource_prefix" {
  type = string
}
variable "resource_tags" {
  type = map(any)
}
