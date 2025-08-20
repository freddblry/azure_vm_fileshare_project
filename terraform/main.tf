terraform {
  backend "azurerm" {
    resource_group_name   = "rg-vm-fileshare"
    storage_account_name  = "filesharestorageacct"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

module "storage" {
  source               = "./modules/storage"
  resource_group_name  = var.resource_group_name
  location             = var.location
  storage_account_name = var.storage_account_name
  file_share_name      = var.file_share_name
}

module "vm" {
  source                = "./modules/vm"
  resource_group_name   = var.resource_group_name
  location              = var.location
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  storage_account_name  = var.storage_account_name
  file_share_name       = var.file_share_name
  storage_account_key   = module.storage.storage_account_key
  vm_size               = var.vm_size
}
