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

output "csv_container_name" {
  description = "Name of the container (filesystem) for CSV data."
  value       = azurerm_storage_data_lake_gen2_filesystem.csv.name
}

output "csv_container_path" {
  description = "ABFS path for uploading CSV: abfss://<container>@<account>.dfs.core.windows.net/"
  value       = "abfss://${azurerm_storage_data_lake_gen2_filesystem.csv.name}@${azurerm_storage_account.adls.name}.dfs.core.windows.net/"
}

output "processed_container_name" {
  description = "Name of the container for processed data (if created)."
  value       = var.create_processed_container ? azurerm_storage_data_lake_gen2_filesystem.processed[0].name : null
}

output "processed_container_path" {
  description = "ABFS path for processed data (if container created)."
  value       = var.create_processed_container ? "abfss://${azurerm_storage_data_lake_gen2_filesystem.processed[0].name}@${azurerm_storage_account.adls.name}.dfs.core.windows.net/" : null
}
