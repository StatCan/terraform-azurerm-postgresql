locals {
  kv_name = var.kv_name
  kv_rg   = var.kv_rg

  kv_workflow_name = var.kv_workflow_name
  kv_workflow_rg   = var.kv_workflow_rg
}

data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "db" {
  count = var.kv_create ? 0 : 1

  name                = local.kv_name
  resource_group_name = local.kv_rg
}

data "azurerm_key_vault" "sqlhstkv" {
  count = (var.diagnostics != null) && var.kv_workflow_enable ? 1 : 0

  name                = local.kv_workflow_name
  resource_group_name = local.kv_workflow_rg
}

data "azurerm_key_vault_secret" "sqlhstsvc" {
  count = (var.diagnostics != null) && var.kv_workflow_enable ? 1 : 0

  name         = "sqlhstsvc"
  key_vault_id = data.azurerm_key_vault.sqlhstkv[count.index].id
}

data "azurerm_key_vault_secret" "saloggingname" {
  count = (var.diagnostics != null) && var.kv_workflow_enable ? 1 : 0

  name         = "saloggingname"
  key_vault_id = data.azurerm_key_vault.sqlhstkv[count.index].id
}

data "azurerm_storage_account" "saloggingname" {
  count = (var.diagnostics != null) && var.kv_workflow_enable ? 1 : 0

  name                = data.azurerm_key_vault_secret.saloggingname[count.index].value
  resource_group_name = var.kv_workflow_salogging_rg
}

#########################################################
# vnet_create (used for storage account network rule)
# => ``null` then no vnet created or attached (default)
# => ``true` then enable creation of new vnet
# => ``false` then point to existing vnet
#########################################################

data "azurerm_virtual_network" "pgsql" {
  count = (var.vnet_create || var.vnet_create == null) ? 0 : 1

  name                = var.vnet_name
  resource_group_name = var.vnet_rg
}

#########################################################
# subnet_create (used for storage account network rule)
# => ``null` then no subnet created or attached (default)
# => ``true` then enable creation of new subnet
# => ``false` then point to existing subnet
#########################################################

data "azurerm_subnet" "pgsql" {
  count = (var.subnet_create || var.subnet_create == null) ? 0 : 1

  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_rg
}
