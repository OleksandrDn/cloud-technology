terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id

  skip_provider_registration = true
}

variable "subscription_id" {
  type = string
}


resource "azurerm_resource_group" "rg" {
  name     = "az104-lab02b-rg"
  location = "East US"

  tags = {
    CostCenter = "000"
  }
}


data "azurerm_policy_definition" "inherit_tag" {
  display_name = "Inherit a tag from the resource group if missing"
}


resource "azurerm_resource_group_policy_assignment" "inherit_tag_assignment" {
  name                 = "inherit-costcenter-from-rg"
  display_name         = "Inherit CostCenter tag from RG"
  description          = "Automatically inherit CostCenter tag from the resource group if missing"
  resource_group_id    = azurerm_resource_group.rg.id
  policy_definition_id = data.azurerm_policy_definition.inherit_tag.id

  location = azurerm_resource_group.rg.location

  parameters = jsonencode({
    tagName = {
      value = "CostCenter"
    }
  })

  identity {
    type = "SystemAssigned"
  }
}


resource "azurerm_management_lock" "rg_lock" {
  name       = "rg-delete-lock"
  scope      = azurerm_resource_group.rg.id
  lock_level = "CanNotDelete"
  notes      = "Protect RG from accidental deletion"
}
