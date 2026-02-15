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
