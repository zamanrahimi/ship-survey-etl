# GitHub Actions

## Deploy data to ADLS

**Workflow:** `deploy-data-to-adls.yml`  
Uploads everything in the `data/` folder to the ADLS Gen2 container **ship-survey-csv**.

### Triggers

- **Manual:** Actions → Deploy data to ADLS → Run workflow
- **On push:** When files under `data/` change on branch `main`

### Setup (one-time)

1. **Create an Azure service principal** (with access to the storage account):
   ```bash
   az ad sp create-for-rbac --name "github-ship-survey-etl" \
     --role "Storage Blob Data Contributor" \
     --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/ship-rg-survey-etl/providers/Microsoft.Storage/storageAccounts/shipsurveyetl
   ```
   Copy the JSON output.

2. **Add GitHub repository secret:**
   - Repo → Settings → Secrets and variables → Actions
   - New repository secret: **`AZURE_CREDENTIALS`**
   - Value: the full JSON from step 1, e.g.:
     ```json
     {"clientId":"...","clientSecret":"...","subscriptionId":"...","tenantId":"..."}
     ```

3. **Optional – override storage account name:**
   - Repo → Settings → Secrets and variables → Actions → Variables
   - New variable: **`AZURE_STORAGE_ACCOUNT`** = your storage account name  
   - If not set, the workflow uses **`shipsurveyetl`** (from Terraform).

After this, run the workflow manually or push changes under `data/` to deploy to **ship-survey-csv**.
