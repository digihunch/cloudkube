output "bastion" {
  value = join(",",data.aws_instances.bastion.ids)
}
