variable "vpc_cidr_block" {
  type = string
}
variable "public_subnets_cidr_list" {
  type = list(any)
}
variable "internalsvc_subnets_cidr_list" {
  type = list(any)
}
variable "datasvc_subnets_cidr_list" {
  type = list(any)
}
variable "node_subnets_cidr_list" {
  type = list(any)
}
variable "pod_subnets_cidr_list" {
  type = list(any)
}
variable "resource_prefix" {
  type = string
}
