# Ship Survey ETL – Terraform (training: step order below)
#
# RUN ORDER: Run this before the GitHub Actions pipeline. After "terraform apply", the pipeline
# can upload data to bronze and run Synapse SQL. Steps Terraform does (in dependency order):
#
#   STEP 1  Resource group (holds everything)
#   STEP 2  Storage account (ADLS Gen2)
#   STEP 3  Containers: bronze, silver, golden + Synapse workspace container
#   STEP 4  Synapse workspace (serverless SQL)
#   STEP 5  Role: Synapse workspace → Storage (so serverless SQL can read bronze/silver/golden)
#   STEP 6  Role: GitHub Actions SP → Storage (so pipeline can upload to bronze)
#   STEP 7  Role: GitHub Actions SP → Synapse (so pipeline can run serverless SQL with Azure AD)
#   STEP 8  (Optional) Role: users/groups → Storage Reader
#
# Then: set GitHub variable SYNAPSE_WORKSPACE_NAME and run the pipeline (push to data/ or manual).

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

# ---------------------------------------------------------------------------
# STEP 1 – Resource group (must exist first; all other resources go in here)
# ---------------------------------------------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# ---------------------------------------------------------------------------
# STEP 2 – Storage account (ADLS Gen2; needed before containers and Synapse)
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# STEP 3 – Containers (filesystems) in the storage account
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# STEP 4 – Synapse workspace (serverless SQL; needs a container for its metadata)
# ---------------------------------------------------------------------------
resource "azurerm_storage_data_lake_gen2_filesystem" "synapse_workspace" {
  name               = var.synapse_workspace_storage_container_name
  storage_account_id = azurerm_storage_account.adls.id
}

resource "azurerm_synapse_workspace" "synapse" {
  name                                 = var.synapse_workspace_name
  resource_group_name                  = azurerm_resource_group.rg.name
  location                             = azurerm_resource_group.rg.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse_workspace.id
  sql_administrator_login              = var.synapse_sql_admin_login
  sql_administrator_login_password     = var.synapse_sql_admin_password

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Allow all IPv4 to reach Synapse (avoids ClientIpAddressNotAuthorized for Terraform and GitHub Actions).
# For production, replace with a specific IP range or use var.synapse_firewall_allowed_ips.
resource "azurerm_synapse_firewall_rule" "allow_all" {
  name                 = "AllowAll"
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "255.255.255.255"
}

# ---------------------------------------------------------------------------
# STEP 5 – Role: Synapse workspace → Storage (so serverless SQL can read/write bronze, silver, golden)
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "synapse_adls_contributor" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.synapse.identity[0].principal_id
}

# ---------------------------------------------------------------------------
# STEP 6 – Role: GitHub Actions SP → Storage (so the pipeline can upload CSVs to bronze)
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# STEP 7 – Role: GitHub Actions SP → Synapse (so the pipeline can run serverless SQL with Azure AD, no password)
# ---------------------------------------------------------------------------
resource "azurerm_synapse_role_assignment" "github_actions_sql" {
  count                = var.github_actions_sp_client_id != "" ? 1 : 0
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  role_name            = "Synapse SQL Administrator"
  principal_id         = data.azuread_service_principal.github_actions[0].object_id
  depends_on           = [azurerm_synapse_firewall_rule.allow_all]
}

# ---------------------------------------------------------------------------
# STEP 8 (optional) – Role: users/groups → Storage Reader (to open containers in Azure Portal)
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "storage_data_reader" {
  for_each             = toset(var.storage_data_reader_principal_ids)
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = each.value
}
