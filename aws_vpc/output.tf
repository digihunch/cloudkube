output "bastion" {
  value = join(",",data.aws_instances.bastion.ids)
}
#output "vpc_id" {
#  value = aws_vpc.eks_vpc.id 
#}
#output "node_subnets_ids" {
#  value = join("\r",aws_subnet.nodesubnets.*.id)
#}
#output "node_subnets_azs" {
#  value = join(",",aws_subnet.nodesubnets.*.availability_zone)
#}

output "bastion_sg_id" {
  value = aws_security_group.bastionsecgrp.id
}
output "next_command" {
  value = "export EKS_REGION=${data.aws_region.this.name}\nexport EKS_VPC_ID=${aws_vpc.eks_vpc.id}\nexport EKS_AZ1=${aws_subnet.nodesubnets[0].availability_zone}\nexport EKS_AZ2=${aws_subnet.nodesubnets[1].availability_zone}\nexport EKS_AZ3=${aws_subnet.nodesubnets[2].availability_zone}\nexport EKS_SUBNET_ID1=${aws_subnet.nodesubnets[0].id}\nexport EKS_SUBNET_ID2=${aws_subnet.nodesubnets[1].id}\nexport EKS_SUBNET_ID3=${aws_subnet.nodesubnets[2].id}\nenvsubst < private-cluster.yaml.tmpl | tee | eksctl create cluster -f - "
}
