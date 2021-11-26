resource "azurerm_monitor_diagnostic_setting" "diag-setting-aks-eventhub" {
  name                           = "${var.resource_prefix}-diag-setting-aks-eventhub"
  target_resource_id             = var.ds_eventhub.tgt_resource_id
  eventhub_name                  = var.ds_eventhub.eventhub_name
  eventhub_authorization_rule_id = var.ds_eventhub.eh_auth_rule_id
  dynamic "log" {
    for_each = var.ds_eventhub.logs
    content {
      category = log.value["category"]
      enabled  = log.value["enabled"]
      retention_policy {
        enabled = log.value["retention_enabled"]
        days    = log.value["retention_days"]
      }
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "diag-setting-aks-laws" {
  name                       = "${var.resource_prefix}-diag-setting-aks-laws"
  target_resource_id         = var.ds_laws.tgt_resource_id
  log_analytics_workspace_id = var.ds_laws.laws_id

  dynamic "log" {
    for_each = var.ds_laws.logs
    content {
      category = log.value["category"]
      enabled  = log.value["enabled"]
      retention_policy {
        enabled = log.value["retention_enabled"]
        days    = log.value["retention_days"]
      }
    }
  }
  metric {
    category = var.ds_laws.metric.category
    enabled  = var.ds_laws.metric.enabled
    retention_policy {
      enabled = var.ds_laws.metric.retention_enabled
      days    = var.ds_laws.metric.retention_days
    }
  }
}
