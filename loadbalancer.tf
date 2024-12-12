

resource "azurerm_lb" "loadbalanacer" {
  name                = "${var.prefix}-lb"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"


  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.pip.id
    # subnet_id            = azurerm_subnet.webSubnet.id
  }
}

resource "azurerm_lb_backend_address_pool" "backendpool" {
  loadbalancer_id = azurerm_lb.loadbalanacer.id
  name            = "BackEndAddressPool"
}




resource "azurerm_lb_rule" "lbruleHTTP" {
  loadbalancer_id                = azurerm_lb.loadbalanacer.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backendpool.id]
  frontend_ip_configuration_name = azurerm_lb.loadbalanacer.frontend_ip_configuration[0].name
  # probe_id                       = azurerm_lb_probe.example.id
}


resource "azurerm_lb_rule" "lbruleSSH" {
  loadbalancer_id                = azurerm_lb.loadbalanacer.id
  name                           = "ssh"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backendpool.id]
  frontend_ip_configuration_name = azurerm_lb.loadbalanacer.frontend_ip_configuration[0].name
  # probe_id                       = azurerm_lb_probe.example.id
}



resource "azurerm_lb_probe" "example" {
  loadbalancer_id = azurerm_lb.loadbalanacer.id
  name            = "http-probe"
  protocol        = "Http"
  request_path    = "/health"
  port            = 8080
}

resource "azurerm_network_interface_backend_address_pool_association" "example" {
  network_interface_id    = azurerm_network_interface.sgrimesProjectNIC.id
  ip_configuration_name   = "testconfiguration1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backendpool.id
}



/*
resource "azurerm_lb_nat_rule" "example" {
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.loadbalanacer.id
  name                           = "SSHAccess"
  protocol                       = "Tcp"
  backend_port                   = 22
  frontend_port                  = 22
  frontend_ip_configuration_name = "PublicIPAddress"

}
*/

/*
resource "azurerm_lb_nat_pool" "lbnatpool" {
  resource_group_name            = var.resource_group_name
  name                           = "ssh"
  loadbalancer_id                = azurerm_lb.loadblanacer.id
  protocol                       = "Tcp"
  frontend_port_start            = 50000
  frontend_port_end              = 50119
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
}
*/