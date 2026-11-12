locals {
  # Alert only on events ingested since the last run: late logs are still
  # caught (query_period covers 1h) and no event alerts twice.
  ingestion_filter = "| where IngestedAt > ago(5m)"

  # One entry per detection. The key is also the .kql file name.
  detections = {
    "03-role-assignment" = {
      display_name = "Privilege escalation: new role assignment"
      description  = "A role assignment was created. MITRE ATT&CK T1098.003."
      severity     = "High"
      tactics      = ["PrivilegeEscalation", "Persistence"]
      techniques   = ["T1098"]
    }
    "04-diagnostic-setting-deleted" = {
      display_name = "Defense evasion: diagnostic setting deleted"
      description  = "Logging was disabled on a resource or subscription. MITRE ATT&CK T1562.008."
      severity     = "High"
      tactics      = ["DefenseEvasion"]
      techniques   = ["T1562"]
    }
    "05-managed-identity-fic-backdoor" = {
      display_name = "Persistence: federated credential added to a managed identity"
      description  = "A federated identity credential was added to a managed identity. MITRE ATT&CK T1098.001."
      severity     = "High"
      tactics      = ["Persistence", "PrivilegeEscalation"]
      techniques   = ["T1098"]
    }
    "06-mass-blob-deletion" = {
      display_name = "Impact: mass deletion of blobs"
      description  = "One caller deleted 10 or more blobs within 5 minutes. MITRE ATT&CK T1485."
      severity     = "High"
      tactics      = ["Impact"]
      techniques   = ["T1485"]
    }
  }
}

resource "azurerm_sentinel_alert_rule_scheduled" "rule" {
  for_each = local.detections

  name                       = "ctd-${each.key}"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.main.workspace_id
  display_name               = each.value.display_name
  description                = each.value.description
  severity                   = each.value.severity
  query                      = "${file("${path.module}/../detections/${each.key}.kql")}\n${local.ingestion_filter}"
  query_frequency            = "PT5M"
  query_period               = "PT1H"
  trigger_operator           = "GreaterThan"
  trigger_threshold          = 0
  tactics                    = each.value.tactics
  techniques                 = each.value.techniques

  entity_mapping {
    entity_type = "Account"
    field_mapping {
      identifier  = "FullName"
      column_name = "Caller"
    }
  }

  entity_mapping {
    entity_type = "IP"
    field_mapping {
      identifier  = "Address"
      column_name = "CallerIpAddress"
    }
  }

  incident {
    create_incident_enabled = true

    grouping {
      enabled                = true
      lookback_duration      = "PT1H"
      entity_matching_method = "AllEntities"
    }
  }
}

moved {
  from = azurerm_sentinel_alert_rule_scheduled.role_assignment
  to   = azurerm_sentinel_alert_rule_scheduled.rule["03-role-assignment"]
}
