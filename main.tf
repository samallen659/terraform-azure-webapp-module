resource "azurerm_resource_group" "rg-main" {
  name     = "rg-${var.project_name}"
  location = var.location
  tags = {
    environment = var.environment
  }
}
