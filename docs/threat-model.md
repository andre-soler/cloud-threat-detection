# Threat Model

## Scope

Azure subscription running the application workloads. In scope: the control plane
(Azure Activity Log), the secrets store (Key Vault) and customer data (Blob Storage).

Out of scope: Entra ID sign-in logs (the lab tenant is not administered by the
consultant), endpoints, on-premises systems and 24x7 monitoring.

## Assets

| Asset | Why it matters |
|---|---|
| Key Vault `prod-db-password`, `payments-api-key` | Whoever reads them can reach production data and payments |
| Storage container `customer-data` | Customer PII export; a leak is a reportable incident |
| Activity Log and diagnostic settings | The evidence trail; attackers disable it to hide |

## Threat actor

An attacker holding a **compromised identity** with Contributor or Owner rights on
the subscription (phished credentials, leaked token, over-privileged automation).
This is the most common path in real cloud breaches: the attacker does not exploit
Azure, they use the same API as legitimate admins.

## Techniques in scope

| # | Attack | MITRE ATT&CK | Log source | Detection signal | Severity | Simulation |
|---|---|---|---|---|---|---|
| 1 | Key Vault secret theft | T1555.006 Cloud Secrets Management Stores | AzureDiagnostics (AuditEvent) | `SecretGet` on several secrets in a short window | Medium | Manual `az keyvault secret show` |
| 2 | Storage key theft and data exfiltration | T1530 Data from Cloud Storage | AzureActivity + StorageBlobLogs | `listKeys` followed by `GetBlob` with `AccountKey` auth | High | Manual key-based download |
| 3 | Privilege escalation via role assignment | T1098.003 Additional Cloud Roles | AzureActivity | `roleAssignments/write` succeeded | High | Manual `az role assignment create` |
| 4 | Disable logging to hide activity | T1562.008 Disable or Modify Cloud Logs | AzureActivity | `diagnosticSettings/delete` | High | Manual deletion of a diagnostic setting |
| 5 | Backdoor a managed identity | T1098 Account Manipulation (persistence) | AzureActivity | `federatedIdentityCredentials/write` | High | Stratus Red Team `azure.persistence.backdoor-managed-identity-fic` |
| 6 | Ransomware-style blob deletion | T1485 Data Destruction | StorageBlobLogs | Many `DeleteBlob` by one caller in minutes | High | Manual bulk delete |

## Detection considerations

- **Legitimate automation produces the same signals.** Terraform calls `listKeys`
  and creates role assignments during normal deployments. Rules must use context
  (sequence of events, caller, source IP) to avoid alert fatigue.
- **Ingestion latency is part of MTTD.** Logs reach the workspace 5 to 15 minutes
  after the event, longer on a new table. No rule can detect faster than that.
- **Data-plane coverage depends on diagnostic settings.** Resources created outside
  Terraform (including Stratus Red Team warm-up resources) only show control-plane
  activity unless a diagnostic setting is added.
