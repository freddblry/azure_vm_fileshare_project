terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

# Random suffix to make global names unique
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  lower   = true
  numeric = true
  special = false
}

locals {
  name_prefix           = "${var.project_name}-${random_string.suffix.result}"
  storage_account_name  = substr(
  replace(lower("${var.project_name}${random_string.suffix.result}"), "[^a-z0-9]", ""),
  0,
  24
)
fileshare_name_lower  = lower(var.fileshare_name)

  cloud_init = <<-EOF
    #cloud-config
    package_update: true
    packages:
      - cifs-utils

    write_files:
      - path: /etc/smbcredentials/${azurerm_storage_account.files.name}.cred
        permissions: '0600'
        owner: root:root
        content: |
          username=${azurerm_storage_account.files.name}
          password=${azurerm_storage_account.files.primary_access_key}

    runcmd:
      - mkdir -p /Projects
      - 'echo "//${azurerm_storage_account.files.name}.file.core.windows.net/${azurerm_storage_share.projects.name} /Projects cifs nofail,vers=3.0,credentials=/etc/smbcredentials/${azurerm_storage_account.files.name}.cred,dir_mode=0777,file_mode=0777,serverino" >> /etc/fstab'
      - mount -a
  EOF
}

#############################
# Networking
#############################
resource "azurerm_resource_group" "rg" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags = {
    project = var.project_name
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.name_prefix}-vnet"
  address_space       = [var.address_space]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${local.name_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_prefix]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${local.name_prefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "pip" {
  name                = "${local.name_prefix}-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
  idle_timeout_in_minutes = 4
}

resource "azurerm_network_interface" "nic" {
  name                = "${local.name_prefix}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#############################
# Storage for Azure Files (mounted at /Projects)
#############################
resource "azurerm_storage_account" "files" {
  name                            = local.storage_account_name
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = false

  # Make sure key access is enabled, needed for mount via SMB
  # (Enabled by default, but set explicitly for clarity)
  # allow_nested_items_to_be_public = false

  tags = {
    project = var.project_name
  }
}

resource "azurerm_storage_share" "projects" {
  name                 = local.fileshare_name_lower
  storage_account_name = azurerm_storage_account.files.name
  quota                = 100
}

#############################
# Linux VM with cloud-init that mounts the Azure File Share
#############################
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "${local.name_prefix}-vm"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  network_interface_ids           = [azurerm_network_interface.nic.id]
  size                            = var.vm_size

  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  # Ubuntu 22.04 LTS (Jammy), Gen2
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    name                 = "${local.name_prefix}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  computer_name = "${var.project_name}-vm"

  custom_data = base64encode(local.cloud_init)

  tags = {
    project = var.project_name
  }
}

output "public_ip_address" {
  description = "Public IP of the VM"
  value       = azurerm_public_ip.pip.ip_address
}

output "fileshare_smb_path" {
  description = "SMB path of the Azure File Share"
  value       = "//${azurerm_storage_account.files.name}.file.core.windows.net/${azurerm_storage_share.projects.name}"
}
