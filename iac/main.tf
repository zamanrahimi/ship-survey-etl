# Ship Survey ETL – Terraform: Azure Data Lake Storage Gen2 for CSV deployment

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource group for ADLS and related resources
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Storage account with Data Lake Storage Gen2 (hierarchical namespace)
resource "azurerm_storage_account" "adls" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  account_kind             = "StorageV2"
  is_hns_enabled           = true # ADLS Gen2
  tags                     = var.tags
}

# Medallion: bronze (raw), silver (cleaned), golden (curated)
resource "azurerm_storage_data_lake_gen2_filesystem" "bronze" {
  name               = var.bronze_container_name
  storage_account_id = azurerm_storage_account.adls.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "silver" {
  name               = var.silver_container_name
  storage_account_id = azurerm_storage_account.adls.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "golden" {
  name               = var.golden_container_name
  storage_account_id = azurerm_storage_account.adls.id
}

# Grant GitHub Actions service principal permission to upload blobs to ADLS
data "azuread_service_principal" "github_actions" {
  count     = var.github_actions_sp_client_id != "" ? 1 : 0
  client_id = var.github_actions_sp_client_id
}

resource "azurerm_role_assignment" "adls_blob_contributor" {
  count                = var.github_actions_sp_client_id != "" ? 1 : 0
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_service_principal.github_actions[0].object_id
}

# Grant users/groups permission to view storage in Azure Portal (Storage Blob Data Reader)
resource "azurerm_role_assignment" "storage_data_reader" {
  for_each             = toset(var.storage_data_reader_principal_ids)
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = each.value
}
