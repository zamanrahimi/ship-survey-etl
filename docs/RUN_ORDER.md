# Run order (training)

Use this order so the pipeline works end-to-end.

---

## 1. Run Terraform first

From the `iac/` folder:

```bash
cd iac
terraform init
terraform apply   # or: terraform apply -auto-approve
```

Terraform does (see comments in `iac/main.tf`):

- **Step 1** – Resource group  
- **Step 2** – Storage account (ADLS Gen2)  
- **Step 3** – Containers: bronze, silver, golden + Synapse workspace container  
- **Step 4** – Synapse workspace (serverless SQL)  
- **Step 5** – Role: Synapse → Storage (so serverless SQL can read bronze/silver/golden)  
- **Step 6** – Role: GitHub Actions SP → Storage (so pipeline can upload to bronze)  
- **Step 7** – Role: GitHub Actions SP → Synapse (so pipeline can run SQL with Azure AD)  
- **Step 8** (optional) – Role: users/groups → Storage Reader  

---

## 2. Set GitHub variable (you already did)

- **Settings → Variables (Actions)** → `SYNAPSE_WORKSPACE_NAME` = `ship-synapse-survey-etl`

---

## 3. Run the pipeline

Either:

- **Push** to `data/**` or `synapse/**` on `main`, or  
- **Actions** tab → **Deploy data to ADLS** → **Run workflow**

The workflow does (see comments in `.github/workflows/deploy-data-to-adls.yml`):

- **Step 1** – Checkout repo  
- **Step 2** – Validate Azure secrets  
- **Step 3** – Azure login (service principal)  
- **Step 4** – Upload `data/` to bronze  
- **Step 5** – List blobs in bronze  
- **Step 6** – Run Synapse serverless SQL (bronze → silver)  

---

## Summary

| Order | What |
|-------|------|
| 1 | Terraform (`iac/` → `terraform apply`) |
| 2 | GitHub variable `SYNAPSE_WORKSPACE_NAME` (you already set it) |
| 3 | Pipeline (push to data/ or manual run) |
