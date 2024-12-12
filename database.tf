resource "azurerm_mssql_server" "example" {
  name                         = "sgrimesmssqlserver"
  resource_group_name          = var.resource_group_name
  location                     = var.resource_group_location
  version                      = "12.0"
  administrator_login          = ""
  administrator_login_password = ""

}


resource "azurerm_mssql_database" "example" {
  name      = "sgrimes-test-db"
  server_id = azurerm_mssql_server.example.id

}

resource "azurerm_private_endpoint" "example" {
  name                = "example-endpoint"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.dbSubnet.id

  private_service_connection {
    name                           = "example-service-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_mssql_server.example.id
    subresource_names = ["sqlServer"]
  }
}

resource "azurerm_mssql_firewall_rule" "example" {
  name             = "AllowFromVNet"
  server_id        = azurerm_mssql_server.example.id
  start_ip_address = "10.0.1.0"
  end_ip_address   = "10.0.1.255"
}