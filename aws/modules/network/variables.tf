variable "vpc_cidr_block" {
  type = string
}
variable "mgmt_subnet_cidr_block" {
  type = string
}
variable "node_subnets_cidr_list" {
  type = list
}
#variable "pod_subnet_cidr_block" {
#  type = string
#}
variable "resource_prefix" {
  type = string
}
variable "resource_tags" {
  type = map(any)
}
