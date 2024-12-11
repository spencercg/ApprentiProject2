resource "azurerm_mssql_server" "example" {
  name                = "sgrimesmssqlserver"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  version             = "12.0"
  administrator_login = ""
  administrator_login_password = ""

}


resource "azurerm_mssql_database" "example" {
  name      = "sgrimes-test-db"
  server_id = azurerm_mssql_server.example.id

}

