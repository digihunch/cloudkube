#variable "node_subnet_id1" {
#  type = string
#}
#variable "node_subnet_id2" {
#  type = string
#}
variable "node_subnet_ids" {
  type = list
}
variable "pod_subnet_id" {
  type = string
}
variable "resource_tags" {
  type = map(any)
}
variable "resource_prefix" {
  type = string
}
