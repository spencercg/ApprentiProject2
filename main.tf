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




resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-pip"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  domain_name_label   = "spencercg92702"

  tags = {
    environment = "test"
  }
}

resource "azurerm_lb" "loadblanacer" {
  name                = "${var.prefix}-lb"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "backendpool" {
  loadbalancer_id = azurerm_lb.loadblanacer.id
  name            = "BackEndAddressPool"
}

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

resource "azurerm_lb_probe" "example" {
  loadbalancer_id = azurerm_lb.loadblanacer.id
  name            = "http-probe"
  protocol        = "Http"
  request_path    = "/health"
  port            = 8080
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


resource "azurerm_virtual_machine_scale_set" "example" {
  name                = "${var.prefix}-vmss"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  # automatic rolling upgrade
  automatic_os_upgrade = true
  upgrade_policy_mode  = "Rolling"

  rolling_upgrade_policy {
    max_batch_instance_percent              = 20
    max_unhealthy_instance_percent          = 20
    max_unhealthy_upgraded_instance_percent = 5
    pause_time_between_batches              = "PT0S"
  }

  # required when using rolling upgrade policy
  health_probe_id = azurerm_lb_probe.example.id

  sku {
    name     = "Standard_F2"
    tier     = "Standard"
    capacity = 2
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix = "testvm"
    admin_username       = ""
    admin_password       = ""
  }

  os_profile_linux_config {
    disable_password_authentication = false
    /*
    ssh_keys {
      path     = "/home/myadmin/.ssh/authorized_keys"
      key_data = file("~/.ssh/demo_key.pub")
    }
    */
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "TestIPConfiguration"
      primary                                = true
      subnet_id                              = azurerm_subnet.webSubnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backendpool.id]
      load_balancer_inbound_nat_rules_ids    = [azurerm_lb_nat_pool.lbnatpool.id]
    }
  }

  tags = {
    environment = "staging"
  }
}