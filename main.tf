terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}


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




resource "azurerm_network_interface" "sgrimesProjectNIC" {
  name                = "${var.prefix}-nic"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name


  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.webSubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


