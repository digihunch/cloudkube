output "bastion" {
  value = join(",",data.aws_instances.bastion.ids)
}
output "vpc_id" {
  value = aws_vpc.eks_vpc.id 
}
output "node_subnets_ids" {
  value = join(",",aws_subnet.nodesubnets.*.id)
}
output "node_subnets_azs" {
  value = join(",",aws_subnet.nodesubnets.*.availability_zone)
}

output "bastion_sg_id" {
  value = aws_security_group.bastionsecgrp.id
}
