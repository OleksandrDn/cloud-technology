
# RESOURCE GROUP
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

# TASK 1-2: ZONAL VMs + SCALE (disk) + NETWORK
resource "azurerm_virtual_network" "vm_vnet" {
  name                = "vm-vnet"
  address_space       = ["10.80.0.0/20"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vm_vnet.name
  address_prefixes     = ["10.80.0.0/24"]
}

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "vm-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-rdp"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "vm_subnet_nsg" {
  subnet_id                 = azurerm_subnet.vm_subnet.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_public_ip" "vm1_pip" {
  name                = "az104-vm1-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [var.vm_zones[0]]
}

resource "azurerm_public_ip" "vm2_pip" {
  name                = "az104-vm2-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [var.vm_zones[1]]
}

resource "azurerm_network_interface" "vm1_nic" {
  name                = "az104-vm1-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm1_pip.id
  }
}

resource "azurerm_network_interface" "vm2_nic" {
  name                = "az104-vm2-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm2_pip.id
  }
}

resource "azurerm_windows_virtual_machine" "vm1" {
  name                = "az104-vm1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  size           = var.vm_size
  admin_username = var.admin_username
  admin_password = var.admin_password

  zone = var.vm_zones[0]

  network_interface_ids = [azurerm_network_interface.vm1_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = null
  }
}

resource "azurerm_windows_virtual_machine" "vm2" {
  name                = "az104-vm2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  size           = var.vm_size
  admin_username = var.admin_username
  admin_password = var.admin_password

  zone = var.vm_zones[1]

  network_interface_ids = [azurerm_network_interface.vm2_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = null
  }
}

# Task 2: storage scaling (data disks)
resource "azurerm_managed_disk" "vm1_data" {
  name                 = "az104-vm1-data1"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "vm1_attach" {
  managed_disk_id    = azurerm_managed_disk.vm1_data.id
  virtual_machine_id = azurerm_windows_virtual_machine.vm1.id
  lun                = 0
  caching            = "ReadWrite"
}

resource "azurerm_managed_disk" "vm2_data" {
  name                 = "az104-vm2-data1"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "vm2_attach" {
  managed_disk_id    = azurerm_managed_disk.vm2_data.id
  virtual_machine_id = azurerm_windows_virtual_machine.vm2.id
  lun                = 0
  caching            = "ReadWrite"
}


# TASK 3-4: VMSS + LB + AUTOSCALE

resource "azurerm_virtual_network" "vmss_vnet" {
  name                = "vmss-vnet"
  address_space       = ["10.82.0.0/20"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "vmss_subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vmss_vnet.name
  address_prefixes     = ["10.82.0.0/24"]
}

resource "azurerm_network_security_group" "vmss_nsg" {
  name                = "vmss1-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-http"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "vmss_subnet_nsg" {
  subnet_id                 = azurerm_subnet.vmss_subnet.id
  network_security_group_id = azurerm_network_security_group.vmss_nsg.id
}

resource "azurerm_public_ip" "vmss_lb_pip" {
  name                = "vmss1-lb-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.vmss_zones
}

resource "azurerm_lb" "vmss_lb" {
  name                = "vmss1-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "public-frontend"
    public_ip_address_id = azurerm_public_ip.vmss_lb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "vmss_backend_pool" {
  name            = "vmss1-backendpool"
  loadbalancer_id = azurerm_lb.vmss_lb.id
}

resource "azurerm_lb_probe" "vmss_probe" {
  name            = "http-probe"
  loadbalancer_id = azurerm_lb.vmss_lb.id
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

resource "azurerm_lb_rule" "vmss_lb_rule" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.vmss_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "public-frontend"
  probe_id                       = azurerm_lb_probe.vmss_probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.vmss_backend_pool.id]
}

resource "azurerm_windows_virtual_machine_scale_set" "vmss" {
  name                = "vmss1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku       = var.vmss_sku
  instances = var.vmss_instances
  zones     = var.vmss_zones

  computer_name_prefix = "vmss1"

  admin_username = var.admin_username
  admin_password = var.admin_password

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.vmss_subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.vmss_backend_pool.id]
    }
  }

  boot_diagnostics {
    storage_account_uri = null
  }

  depends_on = [azurerm_lb_rule.vmss_lb_rule]
}

# Task 4: autoscale VMSS
resource "azurerm_monitor_autoscale_setting" "vmss_autoscale" {
  name                = "vmss1-autoscale"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  target_resource_id  = azurerm_windows_virtual_machine_scale_set.vmss.id

  profile {
    name = "default"

    capacity {
      default = 2
      minimum = 1
      maximum = 5
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT10M"
      }
    }
  }
}

# OUTPUTS

output "vm1_public_ip" {
  value = azurerm_public_ip.vm1_pip.ip_address
}

output "vm2_public_ip" {
  value = azurerm_public_ip.vm2_pip.ip_address
}

output "vmss_lb_public_ip" {
  value = azurerm_public_ip.vmss_lb_pip.ip_address
}
