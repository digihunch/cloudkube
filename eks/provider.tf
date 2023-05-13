terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"
    }
  }
  required_version = ">= 1.4.4"
}

provider "aws" {
  alias = "power-user"
}
provider "aws" {
  alias = "eks-manager"
  assume_role {
    # Do not assume the role until the duration elapsed after role creation.
    role_arn = time_sleep.iam_propagation.triggers["eks_manager_role_arn"]
  }
}
