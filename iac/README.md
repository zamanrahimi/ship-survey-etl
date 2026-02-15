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
- **Role assignment** (optional) – if `github_actions_sp_client_id` is set, Terraform assigns **Storage Blob Data Contributor** on the storage account to that service principal so the GitHub Actions workflow can upload blobs

### Grant GitHub Actions permission via Terraform

To have Terraform assign **Storage Blob Data Contributor** to the service principal used by the deploy-data-to-adls workflow:

1. Create the service principal (if you haven’t): use the same `az ad sp create-for-rbac` or app registration you use for GitHub secrets.
2. In `terraform.tfvars`, set **`github_actions_sp_client_id`** to that service principal’s **Application (client) ID** (same value as the GitHub secret **AZURE_CLIENT_ID**).
3. Run `terraform plan` then `terraform apply`. Terraform will create the role assignment so the workflow can upload to `ship-survey-csv` without a manual `az role assignment create`.

## Deploying CSV later

Upload files to the CSV container using Azure CLI, Synapse pipelines, or the `scripts/` in this repo. Example with Azure CLI (after `az login`):

```bash
az storage blob upload-batch -d ship-survey-csv -s ../data --account-name shipsurveyetl --auth-mode login
```

Use the Terraform output `csv_container_path` (ABFS URL) in Synapse or Spark to read/write data.
