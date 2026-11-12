locals {
  # Alert only on events ingested since the last run: late logs are still
  # caught (query_period covers 1h) and no event alerts twice.
  ingestion_filter = "| where IngestedAt > ago(5m)"
}

resource "azurerm_sentinel_alert_rule_scheduled" "role_assignment" {
  name                       = "ctd-03-role-assignment"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.main.workspace_id
  display_name               = "Privilege escalation: new role assignment"
  description                = "A role assignment was created. MITRE ATT&CK T1098.003."
  severity                   = "High"
  query                      = "${file("${path.module}/../detections/03-role-assignment.kql")}\n${local.ingestion_filter}"
  query_frequency            = "PT5M"
  query_period               = "PT1H"
  trigger_operator           = "GreaterThan"
  trigger_threshold          = 0
  tactics                    = ["PrivilegeEscalation", "Persistence"]
  techniques                 = ["T1098"]

  incident {
    create_incident_enabled = true

    grouping {
      enabled = false
    }
  }
}
