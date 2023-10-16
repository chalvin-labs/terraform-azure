terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }

  cloud {
    organization = "chalvinco"

    workspaces {
      name = "chalvinwz-portfolio"
    }
  }
}

provider "azurerm" {
  features {}
}