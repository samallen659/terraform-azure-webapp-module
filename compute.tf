resource "azurerm_orchestrated_virtual_machine_scale_set" "vmss-main" {
  name                        = "vmss-${var.project_name}"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.rg-main.name
  platform_fault_domain_count = 1
  sku_name                    = "Standard_B1ls"
  instances                   = 1
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
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
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
  upgrade_mode = "Manual"
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
}

resource "azurerm_lb_rule" "lbr-https" {
  loadbalancer_id                = azurerm_lb.lbe-main.id
  name                           = "lbr-https"
  protocol                       = "Tcp"
  frontend_port                  = "443"
  backend_port                   = "443"
  frontend_ip_configuration_name = "PublicIpAddress"
  probe_id                       = azurerm_lb_probe.lprobe-main.id
}

resource "azurerm_lb_probe" "lprobe-main" {
  loadbalancer_id = azurerm_lb.lbe-main.id
  name            = "http-running-probe"
  port            = 80
}
