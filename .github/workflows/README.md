# GitHub Actions

## Deploy data to ADLS

Uploads `data/` to the ADLS bronze container **ship-bronze-data**.

### Auth: two options

**Option A – Account key (quick fix if RBAC fails)**  
1. Get the storage account key: Azure Portal → storage account **shipsurveyetl** → Access keys → key1, or:
   ```bash
   az storage account keys list --account-name shipsurveyetl --query "[0].value" -o tsv
   ```
2. In GitHub: **Settings** → **Secrets and variables** → **Actions** → New secret **`AZURE_STORAGE_ACCOUNT_KEY`** = that key value.
3. Re-run the workflow. It will use key auth and upload will succeed.

**Option B – Service principal (RBAC)**  
1. Ensure the SP used in GitHub (AZURE_CLIENT_ID) has **Storage Blob Data Contributor** on the storage account.
2. **Via Terraform:** In `iac/terraform.tfvars` set `github_actions_sp_client_id = "<same as AZURE_CLIENT_ID in GitHub>"`, then `terraform apply`. Wait 2–5 minutes for RBAC to propagate.
3. Leave **AZURE_STORAGE_ACCOUNT_KEY** unset so the workflow uses login auth.

If you get "You do not have the required permissions", use Option A to unblock, then fix RBAC (Option B) and remove the key secret when done.
