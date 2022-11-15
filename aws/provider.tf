terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.39.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }
  }
  required_version = ">= 1.3.4"
}

provider "aws" {
  alias = "power-user"
}
provider "aws" {
  alias = "eks-manager"
  assume_role {
    #role_arn = "${module.iam.iam_info.eks_manager_role_arn}"
    role_arn = time_sleep.iam_propagation.triggers["eks_manager_role_arn"] 
  }
}
