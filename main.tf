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


resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "West Europe"
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
    source_port_range          = "443"
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
    source_port_range          = "80"
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


resource "azurerm_lb" "loadbalanacer" {
  name                = "${var.prefix}-lb"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name


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


resource "azurerm_lb_nat_rule" "example" {
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.loadbalanacer.id
  name                           = "SSHAccess"
  protocol                       = "Tcp"
  backend_port                   = 22
  frontend_port                  = 22
  frontend_ip_configuration_name = "PublicIPAddress"
  
}

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


resource "azurerm_lb_rule" "lbnatruleHTTP" {
  loadbalancer_id                = azurerm_lb.loadbalanacer.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backendpool.id]
  frontend_ip_configuration_name = azurerm_lb.loadbalanacer.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.example.id
}

/*
resource "azurerm_lb_rule" "lbruleSSH" {
  loadbalancer_id                = azurerm_lb.loadbalanacer.id
  name                           = "ssh"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backendpool.id]
  frontend_ip_configuration_name = azurerm_lb.loadbalanacer.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.example.id
}
*/


resource "azurerm_lb_probe" "example" {
  loadbalancer_id = azurerm_lb.loadbalanacer.id
  name            = "http-probe"
  protocol        = "Http"
  request_path    = "/health"
  port            = 80
}


resource "azurerm_network_interface" "sgrimesProjectNIC" {
  name                = "${var.prefix}-nic"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name



  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.webSubnet.id
    private_ip_address_allocation = "Dynamic"
    # public_ip_address_id = azurerm_public_ip.pip.id
  }
}




resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
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
    admin_username = ""
    admin_password = ""
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}



/*

resource "azurerm_virtual_machine_scale_set" "example" {
  name                = "${var.prefix}-vmss"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  # automatic rolling upgrade
  automatic_os_upgrade = false
  upgrade_policy_mode  = "Automatic"

/*
  rolling_upgrade_policy {
    max_batch_instance_percent              = 20
    max_unhealthy_instance_percent          = 20
    max_unhealthy_upgraded_instance_percent = 5
    pause_time_between_batches              = "PT0S"
  }


  # required when using rolling upgrade policy
  # health_probe_id = azurerm_lb_probe.example.id

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
    admin_password       = "

  os_profile_linux_config {
    disable_password_authentication = false
    /*
    ssh_keys {
      path     = "/home/myadmin/.ssh/authorized_keys"
      key_data = file("~/.ssh/demo_key.pub")
    }
    
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "TestIPConfiguration"
      primary                                = true
      subnet_id                              = azurerm_subnet.webSubnet.id
      # load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backendpool.id]
      # load_balancer_inbound_nat_rules_ids    = [azurerm_lb_rule.lbnatrule.id]
    }
  }

  tags = {
    environment = "staging"
  }
}

*/

resource "azurerm_network_interface_backend_address_pool_association" "example" {
  network_interface_id    = azurerm_network_interface.sgrimesProjectNIC.id
  ip_configuration_name   = "testconfiguration1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backendpool.id
}





