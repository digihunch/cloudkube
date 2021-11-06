variable "vpc_cidr_block" {
  type = string
}
variable "mgmt_subnet_cidr_block" {
  type = string
}
variable "node_subnet_cidr_block" {
  type = string
}
variable "pod_subnet_cidr_block" {
  type = string
}
variable "resource_tags" {
  type = map(any)
}
