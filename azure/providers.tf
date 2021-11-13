terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.78.0"
    }
  }

#  backend "azurerm" {
#  }

  required_version = ">= 1.0.2"
}

provider "azurerm" {
  features {}
}
