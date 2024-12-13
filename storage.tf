resource "azurerm_storage_account" "example" {
  name                     = "sgrimesproject2storage"
  resource_group_name      = var.resource_group_name
  location                 = var.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  public_network_access_enabled = false

  tags = {
    environment = "staging"
  }
}

resource "azurerm_private_endpoint" "storage_ep" {
  name                = "storage-endpoint"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.webSubnet.id

  private_service_connection {
    name                           = "storage-service-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.example.id
    subresource_names              = ["blob"]
  }
}