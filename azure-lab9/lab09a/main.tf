terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116.0"
    }
  }
}

provider "azurerm" {
  features {}
}

#   VARIABLES

variable "rg_name" {
  type    = string
  default = "az104-rg9"
}

variable "location" {
  type    = string
  default = "Central US"
}

variable "webapp_name" {
  type    = string
  default = "az104-lab9-alexD123"
}

#   RESOURCE GROUP


resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location

  tags = {
    lab = "AZ-104-09a"
  }
}

#   APP SERVICE PLAN


resource "azurerm_service_plan" "plan" {
  name                = "${var.webapp_name}-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  os_type  = "Windows"
  sku_name = "S1"

  tags = {
    lab = "AZ-104-09a"
  }
}


#   WEB APP (PRODUCTION)


resource "azurerm_windows_web_app" "webapp" {
  name                = var.webapp_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    minimum_tls_version = "1.2"

    application_stack {
      php_version = "7.4"
    }
  }

  tags = {
    lab = "AZ-104-09a"
  }
}


#   STAGING SLOT


resource "azurerm_windows_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = azurerm_windows_web_app.webapp.id

  site_config {
    minimum_tls_version = "1.2"

    application_stack {
      php_version = "7.4"
    }
  }

  tags = {
    lab = "AZ-104-09a"
  }
}


#   GIT DEPLOYMENT TO STAGING


resource "azurerm_app_service_source_control_slot" "staging_git" {
  slot_id = azurerm_windows_web_app_slot.staging.id

  repo_url               = "https://github.com/Azure-Samples/php-docs-hello-world"
  branch                 = "master"
  use_manual_integration = true
}

#   AUTOSCALE (SERVICE PLAN)


resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = "${var.webapp_name}-autoscale"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  target_resource_id  = azurerm_service_plan.plan.id

  profile {
    name = "AutoScaleDefault"

    capacity {
      default = 1
      minimum = 1
      maximum = 2
    }

    # Scale out (CPU > 70%)
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.plan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        threshold          = 70
        operator           = "GreaterThan"
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    # Scale in (CPU < 30%)
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.plan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        threshold          = 30
        operator           = "LessThan"
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  tags = {
    lab = "AZ-104-09a"
  }
}

#   OUTPUTS

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "webapp_url_production" {
  value = "https://${azurerm_windows_web_app.webapp.default_hostname}"
}

output "webapp_url_staging" {
  value = "https://${azurerm_windows_web_app_slot.staging.default_hostname}"
}
