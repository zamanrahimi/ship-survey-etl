# Ship Survey ETL – Terraform variables

variable "location" {
  description = "Azure region for resources (e.g. East US, West Europe)."
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the resource group for ADLS and related resources (e.g. ship-rg-survey-etl)."
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account (ADLS Gen2). Must be globally unique, 3–24 chars, lowercase alphanumeric only (e.g. shipsurveyetl)."
  type        = string
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

variable "data_lake_container_name" {
  description = "ADLS Gen2 filesystem (container) name for raw CSV data."
  type        = string
  default     = "ship-survey-csv"
}

variable "create_processed_container" {
  description = "Whether to create an additional container for processed/curated data."
  type        = bool
  default     = true
}

variable "processed_container_name" {
  description = "ADLS Gen2 filesystem name for processed data (e.g. Parquet)."
  type        = string
  default     = "ship-survey-processed"
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "github_actions_sp_client_id" {
  description = "Application (client) ID of the service principal used by GitHub Actions to deploy data. If set, Terraform assigns 'Storage Blob Data Contributor' on the storage account so the workflow can upload to ship-survey-csv."
  type        = string
  default     = ""
}
