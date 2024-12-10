resource "azurerm_virtual_machine_scale_set" "example" {
  name                = "mytestscaleset-1"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  # automatic rolling upgrade
  automatic_os_upgrade = false
  upgrade_policy_mode  = "Manual"
/*
  rolling_upgrade_policy {
    max_batch_instance_percent              = 20
    max_unhealthy_instance_percent          = 20
    max_unhealthy_upgraded_instance_percent = 5
    pause_time_between_batches              = "PT0S"
  }
*/
  # required when using rolling upgrade policy
  # health_probe_id = azurerm_lb_probe.example.id

  sku {
    name     = "Standard_d2_v3"
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
      # load_balancer_inbound_nat_rules_ids    = [azurerm_lb_nat_rule.example.id]
    }
  }

  tags = {
    environment = "staging"
  }
}