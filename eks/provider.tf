terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.61.0"
    }
  }
  required_version = ">= 1.9.1"
}

provider "aws" {
  alias = "power-user"
  default_tags {
    tags = {
      Environment = var.CommonTags.Environment
      Owner       = var.CommonTags.Owner
    }
  }
}
provider "aws" {
  alias = "eks-manager"
  assume_role {
    # Do not assume the role until the duration elapsed after role creation.
    role_arn = time_sleep.iam_propagation.triggers["eks_manager_role_arn"]
  }
  default_tags {
    tags = {
      Environment = var.CommonTags.Environment
      Owner       = var.CommonTags.Owner
    }
  }
}
