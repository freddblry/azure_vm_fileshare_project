resource "azurerm_storage_account" "sa" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "share" {
  name                 = var.file_share_name
  storage_account_name = azurerm_storage_account.sa.name
  quota                = 50
}

output "storage_account_key" {
  value     = azurerm_storage_account.sa.primary_access_key
  sensitive = true
}
