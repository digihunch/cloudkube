output "vpc_info" {
  value = {
    vpc_id                 = aws_vpc.eks_vpc.id
    public_subnet_ids      = values(aws_subnet.public_subnets)[*].id
    internalsvc_subnet_ids = values(aws_subnet.internal_subnets)[*].id
    node_subnet_ids        = values(aws_subnet.node_subnets)[*].id # splat expression
    pod_subnets_ids        = values(aws_subnet.pod_subnets)[*].id
  }
}
