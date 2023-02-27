output "iam_info" {
  value = {
    eks_manager_role_arn  = aws_iam_role.eks_manager_role.arn
    eks_manager_role_name = aws_iam_role.eks_manager_role.name
    bastion_role_name     = aws_iam_role.bastion_instance_role.name
  }
}
