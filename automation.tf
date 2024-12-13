resource "azurerm_automation_account" "example" {
  name                = "${var.prefix}-automationaccount"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  sku_name            = "Basic"
}


resource "azurerm_automation_software_update_configuration" "example" {
  name                  = "vmupgradeautomation"
  automation_account_id = azurerm_automation_account.example.id
  # virtual_machine_ids = [azurerm_virtual_machine_scale_set.example.id]
  # operating_system = "Linux"

  linux {
    classifications_included = ["Security"]
    excluded_packages        = ["apt"]
    included_packages        = ["vim"]
    reboot                   = "IfRequired"
  }

  schedule {
    frequency = "Day"
    is_enabled = true 
    time_zone = "Etc/UTC"  
    interval = 1
  } 

    target {
        azure_query {
            scope = ["subscriptions/${var.sub_id}"]
            tag_filter = "All"
        }
        
    }
   
}