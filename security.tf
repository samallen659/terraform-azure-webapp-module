resource "azurerm_user_assigned_identity" "id-vmss-main" {
  name                = "id-vmss-${var.project_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-main.name
}
