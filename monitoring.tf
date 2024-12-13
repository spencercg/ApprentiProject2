resource "azurerm_monitor_action_group" "example" {
  name                = "CriticalAlertsAction"
  resource_group_name = var.resource_group_name
  short_name          = "p0action"

  sms_receiver {
    name         = "oncall-msg"
    country_code = "1"
    phone_number = "${var.phone}"
  }

  tags = {
    user = "${var.user_tag}"
  }
}



resource "azurerm_monitor_metric_alert" "vmsscpualert" {
  name                = "vmsscpu-metricalert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_virtual_machine_scale_set.example.id]
  description         = "Action will be triggered when CPU percentage used is greater than 90."
  severity            = 0

  criteria {
    metric_namespace = "Microsoft.Compute/virtualmachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  
  action {
    action_group_id = azurerm_monitor_action_group.example.id
  }
}

resource "azurerm_monitor_metric_alert" "vmssavailalert" {
  name                = "vmssavail-metricalert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_virtual_machine_scale_set.example.id]
  description         = "Action will be triggered when total number of available VMs is less than two."
  severity            = 1

  criteria {
    metric_namespace = "Microsoft.Compute/virtualmachineScaleSets"
    metric_name      = "VmAvailabilityMetric"
    aggregation      = "Minimum"
    operator         = "LessThan"
    threshold        = 2
  }

  action {
    action_group_id = azurerm_monitor_action_group.example.id
  }
}