output "vpc_info" {
  value = {
    vpc_id           = aws_vpc.eks_vpc.id
    mgmt_subnet_id   = aws_subnet.publicsubnet.id
    node_subnet_id_1 = aws_subnet.nodesubnet1.id
    node_subnet_id_2 = aws_subnet.nodesubnet2.id
    pod_subnet_id    = aws_subnet.podsubnet.id
  }
}
