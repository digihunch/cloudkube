variable "resource_prefix" {
  type = string
}
variable "resource_tags" {
  type = map(any)
}
variable "ds_laws" {
  type = object({
    laws_id         = string,
    tgt_resource_id = string,
    logs = list(object({
      category          = string,
      enabled           = bool,
      retention_enabled = bool,
      retention_days    = number,
    })),
    metric = object({
      category          = string,
      enabled           = bool,
      retention_enabled = bool,
      retention_days    = number,
    }),
  })
}
variable "ds_eventhub" {
  type = object({
    eh_auth_rule_id = string,
    eventhub_name   = string,
    tgt_resource_id = string,
    logs = list(object({
      category          = string,
      enabled           = bool,
      retention_enabled = bool,
      retention_days    = number,
    })),
  })
}
