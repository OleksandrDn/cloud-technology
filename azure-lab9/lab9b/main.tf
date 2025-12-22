
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create resource group (matching lab's az104-rg9)
resource "azurerm_resource_group" "rg" {
  name     = "az104-rg9"
  location = "East US"
}

# Generate unique DNS name label
resource "random_string" "dns_label" {
  length  = 12
  lower   = true
  upper   = false
  special = false
  numeric = true
}

# Deploy Azure Container Instance matching lab configuration
resource "azurerm_container_group" "az104_c1" {
  name                = "az104-c1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Public"
  dns_name_label      = "az104${random_string.dns_label.result}"
  os_type             = "Linux"
  restart_policy      = "Always"

  container {
    name   = "az104-c1"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
    cpu    = 1
    memory = 1.5

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  tags = {
    Environment = "Lab"
  }
}

output "container_fqdn" {
  description = "FQDN of the deployed container instance"
  value       = azurerm_container_group.az104_c1.fqdn
}

output "container_ip_address" {
  description = "Public IP address of the container instance"
  value       = azurerm_container_group.az104_c1.ip_address
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "dns_name_label" {
  description = "DNS name label used"
  value       = azurerm_container_group.az104_c1.dns_name_label
}
