
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = "5965002d-bf76-4c0d-b7e8-9a0b08444687"
  tenant_id       = "104e78cc-6f1d-4a93-b2ce-effee3adb426"
}




resource "azurerm_resource_group" "lab03" {
  name     = "az104-rg3-terraform"
  location = "East US"
}

# Task 1: Create first managed disk 
resource "azurerm_managed_disk" "disk1" {
  name                 = "az104-disk1"
  location             = azurerm_resource_group.lab03.location
  resource_group_name  = azurerm_resource_group.lab03.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32

  tags = {
    Environment = "Lab"
    Task        = "Task1-Portal"
  }
}

# Task 2: Create second disk using template-like approach
resource "azurerm_managed_disk" "disk2" {
  name                 = "az104-disk2"
  location             = azurerm_resource_group.lab03.location
  resource_group_name  = azurerm_resource_group.lab03.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32

  tags = {
    Environment = "Lab"
    Task        = "Task2-CustomTemplate"
  }

  depends_on = [azurerm_managed_disk.disk1]
}

# Task 3: Create third disk 
resource "azurerm_managed_disk" "disk3" {
  name                 = "az104-disk3"
  location             = azurerm_resource_group.lab03.location
  resource_group_name  = azurerm_resource_group.lab03.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32

  tags = {
    Environment = "Lab"
    Task        = "Task3-PowerShell"
  }

  depends_on = [azurerm_managed_disk.disk2]
}

# Task 4: Create fourth disk 
resource "azurerm_managed_disk" "disk4" {
  name                 = "az104-disk4"
  location             = azurerm_resource_group.lab03.location
  resource_group_name  = azurerm_resource_group.lab03.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32

  tags = {
    Environment = "Lab"
    Task        = "Task4-CLI"
  }

  depends_on = [azurerm_managed_disk.disk3]
}

# Task 5: Create fifth disk with different parameters 
resource "azurerm_managed_disk" "disk5" {
  name                 = "az104-disk5"
  location             = azurerm_resource_group.lab03.location
  resource_group_name  = azurerm_resource_group.lab03.name
  storage_account_type = "StandardSSD_LRS"  
  create_option        = "Empty"
  disk_size_gb         = 32

  tags = {
    Environment = "Lab"
    Task        = "Task5-Bicep"
  }

  depends_on = [azurerm_managed_disk.disk4]
}
