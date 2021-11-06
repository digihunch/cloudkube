output "vpc_info" {
  value = {
    vpc_id = aws_vpc.eks_vpc.id
    mgmt_subnet_id = aws_subnet.publicsubnet.id
    node_subnet_id = aws_subnet.nodesubnet.id
    pod_subnet_id = aws_subnet.podsubnet.id
  }
}
