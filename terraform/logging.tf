data "azurerm_subscription" "current" {}

resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "${var.prefix}-activity-to-law"
  target_resource_id         = data.azurerm_subscription.current.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "Policy"
  }

  enabled_log {
    category = "Alert"
  }
}

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "${var.prefix}-kv-to-law"
  target_resource_id         = azurerm_key_vault.victim.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AuditEvent"
  }
}
