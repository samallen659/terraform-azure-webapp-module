data "azurerm_image" "webapp-image" {
  name                = var.image_name
  resource_group_name = "rg-packer-images"
}


resource "azurerm_orchestrated_virtual_machine_scale_set" "vmss-main" {
  name                        = "vmss-${var.project_name}"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.rg-main.name
  platform_fault_domain_count = 1
  sku_name                    = "Standard_B1ls"
  instances                   = 1
  source_image_id             = data.azurerm_image.webapp-image.id
  os_profile {
    linux_configuration {
      admin_username                  = var.admin_username
      admin_password                  = var.admin_password
      disable_password_authentication = false
    }
  }
  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "None"
  }
  network_interface {
    name    = "vmss-nic"
    primary = true
    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.subnet-web.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bep-main.id]
    }
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.id-vmss-main.id]
  }
  upgrade_mode = "Manual"
  # Pass configuration via user_data
  user_data_base64 = base64encode(templatefile("${path.module}/templates/cloud-init.yaml", {
    db_host            = azurerm_postgresql_flexible_server.psqlfsvr-main.fqdn
    db_name            = azurerm_postgresql_flexible_server_database.psqlfsvr-main.name
    db_user            = var.postgesql_user
    key_vault_name     = azurerm_key_vault.kv-main.name
    db_password_secret = azurerm_key_vault_secret.kvs-pgpass.name
  }))
  tags = {
    environment = var.environment
  }
}

resource "azurerm_public_ip" "pip-main" {
  name                = "pip-lbe-${var.project_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-main.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "lbe-main" {
  name                = "lbe-${var.project_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-main.name

  frontend_ip_configuration {
    name                 = "PublicIpAddress"
    public_ip_address_id = azurerm_public_ip.pip-main.id
  }
}

resource "azurerm_lb_backend_address_pool" "bep-main" {
  name            = "bep-${var.project_name}"
  loadbalancer_id = azurerm_lb.lbe-main.id
}

resource "azurerm_lb_rule" "lbr-http" {
  loadbalancer_id                = azurerm_lb.lbe-main.id
  name                           = "lbr-http"
  protocol                       = "Tcp"
  frontend_port                  = "80"
  backend_port                   = "80"
  frontend_ip_configuration_name = "PublicIpAddress"
  probe_id                       = azurerm_lb_probe.lprobe-main.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bep-main.id]
}

resource "azurerm_lb_rule" "lbr-https" {
  loadbalancer_id                = azurerm_lb.lbe-main.id
  name                           = "lbr-https"
  protocol                       = "Tcp"
  frontend_port                  = "443"
  backend_port                   = "443"
  frontend_ip_configuration_name = "PublicIpAddress"
  probe_id                       = azurerm_lb_probe.lprobe-main.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bep-main.id]
}

resource "azurerm_lb_probe" "lprobe-main" {
  loadbalancer_id = azurerm_lb.lbe-main.id
  name            = "http-running-probe"
  port            = 80
}

resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = "autoscale-vmss-${var.project_name}"
  resource_group_name = azurerm_resource_group.rg-main.name
  location            = var.location
  target_resource_id  = azurerm_orchestrated_virtual_machine_scale_set.vmss-main.id
  profile {
    name = "defaultProfile"
    capacity {
      default = var.minimum_vmss_instances
      minimum = var.minimum_vmss_instances
      maximum = var.maximum_vmss_instances
    }
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_orchestrated_virtual_machine_scale_set.vmss-main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 80
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
        dimensions {
          name     = "AppName"
          operator = "Equals"
          values   = ["App1"]
        }
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_orchestrated_virtual_machine_scale_set.vmss-main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
}
