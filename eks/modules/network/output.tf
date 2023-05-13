output "vpc_info" {
  value = {
    vpc_id          = aws_vpc.eks_vpc.id
#    mgmt_subnet_id  = aws_subnet.publicsubnet.id
    public_subnet_ids = aws_subnet.publicsubnets[*].id
    internalsvc_subnet_ids = aws_subnet.internalsvcsubnets[*].id
    datasvc_subnet_ids = aws_subnet.datasvcsubnets[*].id
    node_subnet_ids = aws_subnet.nodesubnets[*].id # splat expression
#    pod_subnet_id    = aws_subnet.podsubnet.id
    pod_subnets_ids = aws_subnet.podsubnets[*].id
  }
}
