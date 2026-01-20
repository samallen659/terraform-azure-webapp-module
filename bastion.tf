resource "azurerm_subnet" "subnet-bastion" {
  count                = var.bastion_required ? 1 : 0
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg-main.name
  virtual_network_name = azurerm_virtual_network.vnet-main.name
  address_prefixes     = ["10.0.255.0/24"]
}

resource "azurerm_public_ip" "pip-bas-main" {
  count               = var.bastion_required ? 1 : 0
  name                = "pip-bas-${var.project_name}"
  resource_group_name = azurerm_resource_group.rg-main.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bas-main" {
  count               = var.bastion_required ? 1 : 0
  name                = "bas-${var.project_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-main.name
  ip_configuration {
    name                 = "ip_configuration"
    subnet_id            = azurerm_subnet.subnet-bastion[0].id
    public_ip_address_id = azurerm_public_ip.pip-bas-main[0].id
  }
  sku = "Basic"
}

