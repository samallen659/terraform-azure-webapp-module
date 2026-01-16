resource "azurerm_orchestrated_virtual_machine_scale_set" "vmss-main" {
  name                        = "vmss-${var.project_name}"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.rg-main.name
  platform_fault_domain_count = 1
  sku_name                    = "Standard_B1ls"
  encryption_at_host_enabled  = true
  instances                   = 1
  os_profile {
    linux_configuration {
      admin_username = var.admin_username
      admin_password = var.admin_password
    }
  }
  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "None"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
  upgrade_mode = "Manual"
  tags = {
    environment = var.environment
  }
}
