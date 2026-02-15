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
   After apply, use the printed outputs (e.g. `bronze_container_path`, `silver_container_path`, `golden_container_path`) in deployment scripts or Synapse.

## Resources created (all names use `ship` prefix)

- **Resource group** `ship-rg-survey-etl` – holds all resources
- **Storage account** `shipsurveyetl` – ADLS Gen2 (hierarchical namespace enabled)
- **Container** `ship-bronze-data` – bronze (raw/landing) – target for GitHub Actions CSV deployment
- **Container** `ship-silver-data` – silver (cleaned)
- **Container** `ship-golden-data` – golden (curated)
- **Role assignment** (optional) – if `github_actions_sp_client_id` is set, Terraform assigns **Storage Blob Data Contributor** on the storage account so the GitHub Actions workflow can upload to **ship-bronze-data**

### Grant GitHub Actions permission via Terraform (so it works every time)

Terraform can manage the **Storage Blob Data Contributor** role assignment so the GitHub Actions workflow can upload to **ship-bronze-data** without a manual `az role assignment create`.

**1. Set the variable**

In `terraform.tfvars`, set **`github_actions_sp_client_id`** to the same value as your GitHub secret **AZURE_CLIENT_ID** (the service principal’s Application (client) ID):

```hcl
github_actions_sp_client_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

**2a. If you have NOT created the role assignment manually yet**

```bash
terraform plan
terraform apply
```

Terraform will create the role assignment.

**2b. If you ALREADY created it via `az role assignment create`**

Import the existing role assignment so Terraform manages it from now on (no duplicate, no destroy/recreate):

```bash
# Get the role assignment ID (replace SUB_ID and AZURE_CLIENT_ID)
ROLE_ID=$(az role assignment list \
  --scope "/subscriptions/<SUB_ID>/resourceGroups/ship-rg-survey-etl/providers/Microsoft.Storage/storageAccounts/shipsurveyetl" \
  --assignee "<AZURE_CLIENT_ID>" \
  --query "[?roleDefinitionName=='Storage Blob Data Contributor'].id" -o tsv)

# Import into Terraform (run from iac/)
terraform import 'azurerm_role_assignment.adls_blob_contributor[0]' "$ROLE_ID"
```

Then run `terraform plan` — it should show no changes (Terraform now owns the assignment). Future `terraform apply` will keep it in place; in a new environment, Terraform will create it.

**3. From now on**

- Every `terraform apply` will ensure the role assignment exists (create if missing, no-op if already there).
- New deployments (e.g. new subscription) get the role automatically when you apply.

## Deploying data later

Upload files to the bronze container using Azure CLI, Synapse pipelines, or the GitHub Actions workflow. Example with Azure CLI (after `az login`):

```bash
az storage blob upload-batch -d ship-bronze-data -s ../data --account-name shipsurveyetl --auth-mode login
```

Use Terraform outputs `bronze_container_path`, `silver_container_path`, `golden_container_path` (ABFS URLs) in Synapse or Spark.


#----- custom comment --- never touch this part -- 
# project instruction

give an end to end abs ships abs ships survey project. provide the full solution using github actions and azure synapse it should 0 to production

ABS Source (CSV/API)
        │
        ▼
Azure Data Lake Gen2 (Raw Zone)
        │
        ▼
Synapse Spark (Bronze → Silver)
        │
        ▼
Synapse Dedicated SQL Pool (Gold Layer)
        │
        ▼
Power BI / Reporting
