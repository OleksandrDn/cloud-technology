terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.1.0"
}

provider "azuread" {}

data "azuread_domains" "primary" {
  only_initial = true
}



resource "azuread_user" "az104_user1" {
  user_principal_name   = "az104-user1@${data.azuread_domains.primary.domains[0].domain_name}"
  display_name          = "az104-user1"
  password              = "P@ssword1234!"
  force_password_change = false
  job_title             = "IT Lab Administrator"
  department            = "IT"
  usage_location        = "US"
  account_enabled       = true
}

resource "azuread_invitation" "external_user" {
  user_email_address = "oleksandr.test.lab@gmail.com"
  redirect_url       = "https://portal.azure.com"
  user_display_name  = "Oleksandr DanyliukTEST"
  user_type          = "Guest"
  message {
    body = "Welcome to Azure and our group project!!!"
  }
}




resource "azuread_group" "it_lab_admins" {
  display_name     = "IT Lab Administrators"
  description      = "Administrators that manage the IT lab"
  security_enabled = true
}

resource "azuread_group_member" "add_az104_user1" {
  group_object_id  = azuread_group.it_lab_admins.object_id
  member_object_id = azuread_user.az104_user1.object_id
}

resource "azuread_group_member" "add_external_user" {
  group_object_id  = azuread_group.it_lab_admins.object_id
  member_object_id = azuread_invitation.external_user.user_id
}







