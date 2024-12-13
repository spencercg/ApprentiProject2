resource "azurerm_virtual_network" "sgrimesProjectVNet" {
  name                = "${var.prefix}-VNet"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]

}


resource "azurerm_subnet" "webSubnet" {
  name                 = "webSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.sgrimesProjectVNet.name
  address_prefixes     = ["10.0.1.0/24"]
}



resource "azurerm_subnet" "dbSubnet" {
  name                 = "dbSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.sgrimesProjectVNet.name
  address_prefixes     = ["10.0.2.0/24"]
}


resource "azurerm_subnet" "storageSubnetSubnet" {
  name                 = "storageSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.sgrimesProjectVNet.name
  address_prefixes     = ["10.0.3.0/24"]
}


resource "azurerm_network_security_group" "example" {
  name                = "webSubnetNSG"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  security_rule {
    name                       = "InboundHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "InboundICMP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "InboundHTTP"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "InboundSSH"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }



  tags = {
    environment = "testing"
  }
}



resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.webSubnet.id
  network_security_group_id = azurerm_network_security_group.example.id
}




resource "azurerm_network_security_group" "dbnsg" {
  name                = "dbSubnetNSG"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  security_rule {
    name                       = "InboundHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "InboundICMP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "InboundHTTP"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "InboundSSH"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }



  tags = {
    environment = "testing"
  }
}



resource "azurerm_subnet_network_security_group_association" "dbnsgassoc" {
  subnet_id                 = azurerm_subnet.dbSubnet.id
  network_security_group_id = azurerm_network_security_group.dbnsg.id
}



resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-pip"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  domain_name_label   = "spencercg92702"
  sku                 = "Standard"


  tags = {
    environment = "test"
  }
}






resource "azurerm_network_interface" "sgrimesProjectNIC" {
  name                = "${var.prefix}-nic"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name



  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.webSubnet.id
    private_ip_address_allocation = "Dynamic"
    # public_ip_address_id          = azurerm_public_ip.pip.id
  }
}



