

resource "azurerm_virtual_machine_scale_set" "example" {
  name                = "${var.prefix}-vmss"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

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


  # required when using rolling upgrade
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
    admin_username       = "${var.vm_username}"
    admin_password       = "${var.vm_auth}"
    custom_data = filebase64("user.sh")

  }

  os_profile_linux_config {
    disable_password_authentication = false
    
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "vmssipconfig"
      primary                                = true
      subnet_id                              = azurerm_subnet.webSubnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backendpool.id]
    }
  }


  tags = {
    user = "${var.user_tag}"
  }
}

resource "azurerm_monitor_autoscale_setting" "example" {
  name                = "vmssautoscalesetting"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  profile {
    name = "vmssautoscaleprofile"
    capacity {
      default = 2
      maximum = 4
      minimum = 2
    }
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.example.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 80
      }
      scale_action {
        cooldown  = "PT5M"
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
      }
    }
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.example.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 50
      }
      scale_action {
        cooldown  = "PT5M"
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1
      }
    }

  }
  target_resource_id = azurerm_virtual_machine_scale_set.example.id
  enabled            = true


  tags = {
    user = "${var.user_tag}"
  }

}
