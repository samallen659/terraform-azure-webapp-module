resource "azurerm_orchestrated_virtual_machine_scale_set" "vmss-main" {
  name                        = "vmss-${var.project_name}"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.rg-main.name
  platform_fault_domain_count = 1
  sku_name                    = "B1ls"
  encryption_at_host_enabled  = true
  instances                   = 1
  os_profile {
    linux_configuration {
      admin_username = var.admin_username
      admin_password = var.admin_password
    }
  }
  upgrade_mode = "Rolling"
  rolling_upgrade_policy {
    max_batch_instance_percent              = 50
    max_unhealthy_instance_percent          = 50
    max_unhealthy_upgraded_instance_percent = 50
    pause_time_between_batches              = "PT6H"
  }
  tags = {
    environment = var.environment
  }
}
