terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.65.0"
    }
  }

  #  backend "azurerm" {
  #  }

  required_version = ">= 1.5.2"
}

provider "azurerm" {
  features {}
}
