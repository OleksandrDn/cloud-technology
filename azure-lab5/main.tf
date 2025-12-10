terraform {
  required_version = ">= 1.1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "rg" {
  name     = "az104-rg5"
  location = "Poland Central"
}

# Task 1
resource "azurerm_virtual_network" "core_vnet" {
  name                = "CoreServicesVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "core_subnet" {
  name                 = "Core"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.core_vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}


resource "azurerm_network_interface" "core_nic" {
  name                = "CoreServicesVM-NIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.core_subnet.id
  }
}


resource "azurerm_windows_virtual_machine" "core_vm" {
  name                = "CoreServicesVM"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2a_v4"

  admin_username = "localadmin"
  admin_password = "ChangeThisPassword123!" 

  network_interface_ids = [
    azurerm_network_interface.core_nic.id
  ]

  os_disk {
    name                 = "CoreServicesVM-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter-gensecond"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = null
  }
}


# Task 2

resource "azurerm_virtual_network" "manufacturing_vnet" {
  name                = "ManufacturingVnet"
  address_space       = ["172.16.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "manufacturing_subnet" {
  name                 = "Manufacturing"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.manufacturing_vnet.name
  address_prefixes     = ["172.16.0.0/24"]
}

resource "azurerm_network_interface" "manufacturing_nic" {
  name                = "ManufacturingVM-NIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.manufacturing_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "manufacturing_vm" {
  name                = "ManufacturingVM"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2a_v4"   # STABLE ALTERNATIVE FOR DS2_v3

  admin_username = "localadmin"
  admin_password = "ChangeThisPassword123!" 

  network_interface_ids = [
    azurerm_network_interface.manufacturing_nic.id
  ]

  os_disk {
    name                 = "ManufacturingVM-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter-gensecond"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = null
  }
}

# Task 4

resource "azurerm_virtual_network_peering" "core_to_manufacturing" {
  name                      = "CoreServicesVnet-to-ManufacturingVnet"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.core_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.manufacturing_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "manufacturing_to_core" {
  name                      = "ManufacturingVnet-to-CoreServicesVnet"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.manufacturing_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.core_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# Task 6

resource "azurerm_subnet" "core_perimeter" {
  name                 = "perimeter"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.core_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_route_table" "rt_core" {
  name                = "rt-CoreServices"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_route" "perimeter_to_core" {
  name                = "PerimetertoCore"
  resource_group_name = azurerm_resource_group.rg.name
  route_table_name    = azurerm_route_table.rt_core.name

  address_prefix = "10.0.0.0/16"   # CoreServices network
  next_hop_type  = "VirtualAppliance"
  next_hop_in_ip_address = "10.0.1.7"   # майбутній NVA
}

resource "azurerm_subnet_route_table_association" "core_subnet_association" {
  subnet_id      = azurerm_subnet.core_subnet.id
  route_table_id = azurerm_route_table.rt_core.id
}






