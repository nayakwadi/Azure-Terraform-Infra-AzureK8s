terraform {
  backend "azurerm" {
    resource_group_name  = "snoperatios-rg"
    storage_account_name = "stgaccntsniacterra"
    container_name       = "akskvtfstate"
    key                  = "aks-dev.terraform.tfstate"
  }
}
