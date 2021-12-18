variable "node_subnet_ids" {
  type = list(any)
}
variable "vpc_id" {
  type = string
}
variable "resource_tags" {
  type = map(any)
}
variable "resource_prefix" {
  type = string
}
