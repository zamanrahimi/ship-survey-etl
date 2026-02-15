# IaC – Terraform (Azure ADLS Gen2)

Terraform in this folder provisions **Azure Data Lake Storage Gen2** for the Ship Survey ETL project. Use it to create the storage account and containers where CSV (and later processed) data will be deployed.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and logged in: `az login`
- Sufficient Azure subscription permissions to create resource groups and storage accounts

## Quick start

1. **Copy example variables and edit**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
   Edit `terraform.tfvars`: set `resource_group_name`, `storage_account_name` (globally unique, 3–24 chars, lowercase alphanumeric), and `location` as needed.

2. **Initialize and plan**
   ```bash
   terraform init
   terraform plan
   ```

3. **Apply**
   ```bash
   terraform apply
   ```

4. **Use outputs**  
   After apply, use the printed outputs (e.g. `csv_container_path`) in deployment scripts or Synapse to upload CSVs from `data/` to ADLS.

## Resources created (all names use `ship` prefix)

- **Resource group** `ship-rg-survey-etl` – holds all resources
- **Storage account** `shipsurveyetl` – ADLS Gen2 (hierarchical namespace enabled)
- **Container** `ship-survey-csv` – target for raw CSV deployment
- **Container** `ship-survey-processed` (optional) – for processed/curated data (e.g. Parquet)

## Deploying CSV later

Upload files to the CSV container using Azure CLI, Synapse pipelines, or the `scripts/` in this repo. Example with Azure CLI (after `az login`):

```bash
az storage blob upload-batch -d ship-survey-csv -s ../data --account-name shipsurveyetl --auth-mode login
```

Use the Terraform output `csv_container_path` (ABFS URL) in Synapse or Spark to read/write data.
