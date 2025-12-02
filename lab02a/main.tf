terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azuread" {}


variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

resource "azurerm_management_group" "mg1" {
  name         = "az104-mg1"
  display_name = "az104-mg1"
}

resource "azurerm_management_group_subscription_association" "mg_sub" {
  management_group_id = azurerm_management_group.mg1.id
  subscription_id     = "/subscriptions/${var.subscription_id}"
}


resource "azuread_group" "helpdesk" {
  display_name     = "az104-helpdesk"
  security_enabled = true
}

resource "azurerm_role_assignment" "helpdesk_role" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_group.helpdesk.object_id
}
