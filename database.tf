
resource "azurerm_mssql_server" "example" {
  name                         = "${var.prefix}-sqlserver"
  resource_group_name          = var.resource_group_name
  location                     = var.resource_group_location
  version                      = "12.0"
  administrator_login          = "${var.db_username}"
  administrator_login_password = "${var.db_auth}"
  
  tags = {
    user = "${var.user_tag}"
  }
}


resource "azurerm_mssql_database" "example" {
  name      = "${var.prefix}-db"
  server_id = azurerm_mssql_server.example.id

  tags = {
    user = "${var.user_tag}"
  }

}

resource "azurerm_private_endpoint" "example" {
  name                = "db-endpoint"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.dbSubnet.id

  private_service_connection {
    name                           = "db-service-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_mssql_server.example.id
    subresource_names              = ["sqlServer"]
  }

  tags = {
    user = "${var.user_tag}"
  }
}



resource "azurerm_mssql_firewall_rule" "example" {
  name             = "AllowFromWebSubnet"
  server_id        = azurerm_mssql_server.example.id
  start_ip_address = "10.0.1.0"
  end_ip_address   = "10.0.1.255"
}
