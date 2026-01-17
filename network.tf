resource "azurerm_virtual_network" "vnet-main" {
  name                = "vnet-${var.project_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-main.name
  address_space       = ["10.0.0.0/16"]
  tags = {
    environment = var.environment
  }
}

resource "azurerm_subnet" "subnet-web" {
  name                 = "subnet-web"
  resource_group_name  = azurerm_resource_group.rg-main.name
  virtual_network_name = azurerm_virtual_network.vnet-main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet-db" {
  name                 = "subnet-db"
  resource_group_name  = azurerm_resource_group.rg-main.name
  virtual_network_name = azurerm_virtual_network.vnet-main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "subnet-bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg-main.name
  virtual_network_name = azurerm_virtual_network.vnet-main.name
  address_prefixes     = ["10.0.255.0/24"]
}

resource "azurerm_public_ip" "pip-bas-main" {
  name                = "pip-bas-${var.project_name}"
  resource_group_name = azurerm_resource_group.rg-main.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bas-main" {
  name                = "bas-${var.project_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-main.name
  ip_configuration {
    name                 = "ip_configuration"
    subnet_id            = azurerm_subnet.subnet-bastion.id
    public_ip_address_id = azurerm_public_ip.pip-bas-main.id
  }
  sku = "Basic"
}

resource "azurerm_network_security_group" "nsg-main" {
  name                = "nsg-${var.project_name}"
  resource_group_name = azurerm_resource_group.rg-main.name
  location            = var.location
  tags = {
    environment = var.environment
  }
}

resource "azurerm_network_security_rule" "rule-web-http" {
  name                        = "AllowHTTP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "10.0.1.0/24"
  resource_group_name         = azurerm_resource_group.rg-main.name
  network_security_group_name = azurerm_network_security_group.nsg-main.name
}

resource "azurerm_network_security_rule" "rule-web-https" {
  name                        = "AllowHTTPS"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "10.0.1.0/24"
  resource_group_name         = azurerm_resource_group.rg-main.name
  network_security_group_name = azurerm_network_security_group.nsg-main.name
}

resource "azurerm_network_security_rule" "rule-db-5432" {
  name                        = "AllowPostgesql"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = "10.0.1.0/24"
  destination_address_prefix  = "10.0.2.0/24"
  resource_group_name         = azurerm_resource_group.rg-main.name
  network_security_group_name = azurerm_network_security_group.nsg-main.name
}

resource "azurerm_network_security_rule" "rule-db-block" {
  name                        = "BlockALL"
  priority                    = 103
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "10.0.2.0/24"
  resource_group_name         = azurerm_resource_group.rg-main.name
  network_security_group_name = azurerm_network_security_group.nsg-main.name
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.subnet-web.id
  network_security_group_id = azurerm_network_security_group.nsg-main.id
}

resource "azurerm_subnet_network_security_group_association" "db" {
  subnet_id                 = azurerm_subnet.subnet-db.id
  network_security_group_id = azurerm_network_security_group.nsg-main.id
}
