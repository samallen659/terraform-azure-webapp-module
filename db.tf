resource "azurerm_private_dns_zone" "pdns-main" {
  name                = "${var.project_name}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg-main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pdns-link-main" {
  name                  = "${var.project_name}vnetzone.com"
  private_dns_zone_name = azurerm_private_dns_zone.pdns-main.name
  virtual_network_id    = azurerm_virtual_network.vnet-main.id
  resource_group_name   = azurerm_resource_group.rg-main.name
  depends_on            = [azurerm_subnet.subnet-db]
}

resource "azurerm_postgresql_flexible_server" "psqlfsvr-main" {
  name                          = "psqlfsvr-${var.project_name}"
  resource_group_name           = azurerm_resource_group.rg-main.name
  location                      = var.location
  version                       = "17"
  delegated_subnet_id           = azurerm_subnet.subnet-db.id
  private_dns_zone_id           = azurerm_private_dns_zone.pdns-main.id
  public_network_access_enabled = false
  administrator_login           = var.postgesql_user
  administrator_password        = var.postgresql_password
  zone                          = "1"

  storage_mb   = 32768
  storage_tier = "P4"

  sku_name   = "B_Standard_B1ms"
  depends_on = [azurerm_private_dns_zone_virtual_network_link.pdns-link-main]
}

resource "azurerm_postgresql_flexible_server_database" "psqldb-main" {
  name      = var.project_name
  server_id = azurerm_postgresql_flexible_server.psqlfsvr-main.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}
