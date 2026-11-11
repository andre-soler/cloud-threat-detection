data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_key_vault" "victim" {
  name                       = "${var.prefix}-kv-${random_string.suffix.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  tags                       = var.tags
}

resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.victim.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "random_password" "fake_db" {
  length  = 24
  special = true
}

resource "random_password" "fake_api_key" {
  length  = 32
  special = false
}

resource "azurerm_key_vault_secret" "fake_db_password" {
  name         = "prod-db-password"
  value        = random_password.fake_db.result
  key_vault_id = azurerm_key_vault.victim.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "fake_api_key" {
  name         = "payments-api-key"
  value        = random_password.fake_api_key.result
  key_vault_id = azurerm_key_vault.victim.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}
