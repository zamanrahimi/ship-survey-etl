# Ship Survey ETL – Terraform outputs (for scripts / Synapse / GitHub Actions)

output "resource_group_name" {
  description = "Name of the created resource group."
  value       = azurerm_resource_group.rg.name
}

output "storage_account_name" {
  description = "Name of the ADLS Gen2 storage account."
  value       = azurerm_storage_account.adls.name
}

output "storage_account_id" {
  description = "Resource ID of the storage account."
  value       = azurerm_storage_account.adls.id
}

output "storage_account_primary_dfs_endpoint" {
  description = "Primary DFS (Data Lake) endpoint for ADLS Gen2."
  value       = azurerm_storage_account.adls.primary_dfs_endpoint
}

output "bronze_container_name" {
  description = "Name of the bronze (raw) container."
  value       = azurerm_storage_data_lake_gen2_filesystem.bronze.name
}

output "bronze_container_path" {
  description = "ABFS path for bronze data."
  value       = "abfss://${azurerm_storage_data_lake_gen2_filesystem.bronze.name}@${azurerm_storage_account.adls.name}.dfs.core.windows.net/"
}

output "silver_container_name" {
  description = "Name of the silver (cleaned) container."
  value       = azurerm_storage_data_lake_gen2_filesystem.silver.name
}

output "silver_container_path" {
  description = "ABFS path for silver data."
  value       = "abfss://${azurerm_storage_data_lake_gen2_filesystem.silver.name}@${azurerm_storage_account.adls.name}.dfs.core.windows.net/"
}

output "golden_container_name" {
  description = "Name of the golden (curated) container."
  value       = azurerm_storage_data_lake_gen2_filesystem.golden.name
}

output "golden_container_path" {
  description = "ABFS path for golden data."
  value       = "abfss://${azurerm_storage_data_lake_gen2_filesystem.golden.name}@${azurerm_storage_account.adls.name}.dfs.core.windows.net/"
}
