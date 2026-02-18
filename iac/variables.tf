# Ship Survey ETL – Terraform variables

variable "location" {
  description = "Azure region for all resources (RG, storage, Synapse). Use a region that allows Synapse (e.g. East US 2 if East US fails with SqlServerRegionDoesNotAllowProvisioning)."
  type        = string
  default     = "East US 2"
}

variable "resource_group_name" {
  description = "Name of the resource group for ADLS and related resources (e.g. ship-rg-survey-etl)."
  type        = string
  default     = "ship-rg-survey-etl"
}

variable "storage_account_name" {
  description = "Name of the storage account (ADLS Gen2). Must be globally unique, 3–24 chars, lowercase alphanumeric only (e.g. shipsurveyetl)."
  type        = string
  default     = "shipsurveyetl"
}

variable "storage_account_tier" {
  description = "Storage account tier: Standard or Premium."
  type        = string
  default     = "Standard"
}

variable "storage_account_replication_type" {
  description = "Replication type: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  type        = string
  default     = "LRS"
}

variable "bronze_container_name" {
  description = "ADLS Gen2 filesystem name for bronze (raw/landing) data."
  type        = string
  default     = "ship-bronze-data"
}

variable "silver_container_name" {
  description = "ADLS Gen2 filesystem name for silver (cleaned) data."
  type        = string
  default     = "ship-silver-data"
}

variable "golden_container_name" {
  description = "ADLS Gen2 filesystem name for golden (curated) data."
  type        = string
  default     = "ship-golden-data"
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "github_actions_sp_client_id" {
  description = "Application (client) ID of the service principal used by GitHub Actions to deploy data. If set, Terraform assigns 'Storage Blob Data Contributor' on the storage account so the workflow can upload to ship-bronze-data."
  type        = string
  default     = ""
}

variable "storage_data_reader_principal_ids" {
  description = "List of Azure AD object IDs (users or groups) to grant 'Storage Blob Data Reader' on the storage account so they can open containers in the Azure Portal."
  type        = list(string)
  default     = []
}

# ------------------------------------------------------------------------------
# Synapse workspace (serverless SQL): query bronze/silver/golden via OPENROWSET/CETAS.
# Do not commit synapse_sql_admin_password in tfvars; use TF_VAR or a secret store.
# ------------------------------------------------------------------------------
variable "synapse_workspace_name" {
  description = "Name of the Azure Synapse workspace (serverless SQL)."
  type        = string
  default     = "ship-synapse-survey-etl"
}

variable "synapse_workspace_storage_container_name" {
  description = "ADLS Gen2 container used as primary storage for the Synapse workspace (metadata, not medallion data)."
  type        = string
  default     = "ship-synapse-workspace"
}

variable "synapse_sql_admin_login" {
  description = "SQL administrator login for the Synapse workspace (used for dedicated pools; serverless SQL can use AAD)."
  type        = string
  default     = "sqladmin"
}

variable "synapse_sql_admin_password" {
  description = "SQL administrator password for the Synapse workspace. Prefer passing via TF_VAR_synapse_sql_admin_password or a secret store."
  type        = string
  sensitive   = true
}
