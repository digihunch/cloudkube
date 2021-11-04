resource "azurerm_monitor_diagnostic_setting" "diag-setting-aks-eventhub" {
  name                           = "${var.resource_prefix}-diag-setting-aks-eventhub"
  target_resource_id             = var.ds_eh_aks_id
  eventhub_name                  = var.ds_eh_name
  eventhub_authorization_rule_id = var.ds_ehar_id

  log {
    category = "kube-scheduler"
    enabled  = true
    retention_policy {
      enabled = false
    }
  }
  log {
    category = "kube-apiserver"
    enabled  = true
    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "diag-setting-aks-laws" {
  name                       = "${var.resource_prefix}-diag-setting-aks-laws"
  target_resource_id         = var.ds_eh_aks_id
  log_analytics_workspace_id = var.ds_laws_id

  log {
    category = "kube-scheduler"
    enabled  = true
    retention_policy {
      enabled = false
    }
  }
  log {
    category = "kube-apiserver"
    enabled  = true
    retention_policy {
      enabled = false
    }
  }
  metric {
    category = "AllMetrics"
    retention_policy {
      enabled = false
    }
  }
}
