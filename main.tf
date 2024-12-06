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


resource "azurerm_virtual_machine" "webVM001" {
  name                  = "${var.prefix}-webVM001"
  location              = var.resource_group_location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.sgrimesProjectNIC.id]
  vm_size               = "Standard_d2_v3"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}