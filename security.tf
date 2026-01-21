data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "id-vmss-main" {
  name                = "id-vmss-${var.project_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-main.name
}

resource "azurerm_key_vault" "kv-main" {
  name                       = "kv-${var.project_name}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg-main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled   = false
  sku_name                   = "standard"
  rbac_authorization_enabled = true
}

resource "azurerm_key_vault_secret" "kvs-pgpass" {
  name         = "pgpass-${var.project_name}"
  value        = var.postgresql_password
  key_vault_id = azurerm_key_vault.kv-main.id
}

resource "azurerm_role_assignment" "role-kv" {
  scope                            = azurerm_key_vault.kv-main.id
  role_definition_name             = "Key Vault Secrets User"
  principal_id                     = azurerm_user_assigned_identity.id-vmss-main.principal_id
  skip_service_principal_aad_check = true
  principal_type                   = "ServicePrincipal"
}
