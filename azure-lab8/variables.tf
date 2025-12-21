variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "westus2"
}

variable "rg_name" {
  type    = string
  default = "az104-rg8"
}

variable "admin_username" {
  type    = string
  default = "localadmin"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "VM admin password"
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "vm_zones" {
  type    = list(string)
  default = ["1", "2"]
}

variable "data_disk_size_gb" {
  type    = number
  default = 16
}

variable "vmss_sku" {
  type    = string
  default = "Standard_B2s"
}

variable "vmss_instances" {
  type    = number
  default = 2
}

variable "vmss_zones" {
  type    = list(string)
  default = ["1", "2", "3"]
}
