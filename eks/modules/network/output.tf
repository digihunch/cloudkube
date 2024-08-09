output "vpc_info" {
  value = {
    vpc_id                 = aws_vpc.eks_vpc.id
    public_subnet_ids      = aws_subnet.publicsubnets[*].id
    internalsvc_subnet_ids = aws_subnet.internalsvcsubnets[*].id
    node_subnet_ids        = aws_subnet.nodesubnets[*].id # splat expression
    pod_subnets_ids        = aws_subnet.podsubnets[*].id
  }
}
