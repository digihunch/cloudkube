terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.85.0"
    }
  }

  #  backend "azurerm" {
  #  }

  required_version = ">= 1.6.6"
}

provider "azurerm" {
  features {}
}
