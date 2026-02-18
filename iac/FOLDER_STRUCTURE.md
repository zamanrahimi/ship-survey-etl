# IaC folder structure and what each file does

This folder uses **Terraform** to create Azure resources for the Ship Survey ETL project (resource group, ADLS Gen2 storage, Synapse workspace). Below is what each file is for.

---

## Folder layout

```
iac/
├── main.tf                    # Resources: RG, storage, containers, Synapse, role assignments
├── variables.tf               # Input variable definitions (with defaults and descriptions)
├── outputs.tf                 # Values printed after apply (names, paths, IDs)
├── terraform.tfvars           # Your values (create from example; often not committed)
├── terraform.tfvars.example   # Template for terraform.tfvars
├── README.md                  # How to run Terraform and what it creates
├── FOLDER_STRUCTURE.md        # This file
├── .terraform/                # Created by terraform init (providers, modules)
├── terraform.tfstate          # Created by terraform apply (current state; do not edit)
└── terraform.tfstate.backup   # Backup of previous state (if present)
```

---

## File-by-file

| File | Purpose |
|------|--------|
| **main.tf** | Defines all Azure resources and the order they are created: resource group → storage account → containers (bronze, silver, golden, Synapse workspace container) → Synapse workspace → role assignments (Synapse→Storage, GitHub SP→Storage, GitHub SP→Synapse, optional reader). Contains step comments (STEP 1–8) for training. |
| **variables.tf** | Declares every input variable: `location`, `resource_group_name`, `storage_account_name`, container names, Synapse settings, `github_actions_sp_client_id`, tags, etc. Includes type, description, and optional default so you can override them in tfvars or CLI. |
| **outputs.tf** | Exposes useful values after `terraform apply`: resource group name, storage account name/id/endpoint, bronze/silver/golden container names and ABFS paths, Synapse workspace name and ID. Used by scripts, Synapse, or GitHub (e.g. `terraform output synapse_workspace_name`). |
| **terraform.tfvars** | Your actual variable values for this environment (e.g. location, resource group name, storage account name, `github_actions_sp_client_id`, Synapse name/login). Created by copying `terraform.tfvars.example`. Often not committed if it contains secrets. Terraform loads it automatically. |
| **terraform.tfvars.example** | Example/skeleton for `terraform.tfvars`. Safe to commit. Copy to `terraform.tfvars` and fill in your values. Documents optional variables (containers, Synapse, reader IDs). |
| **README.md** | Human-readable guide: prerequisites, quick start (init, plan, apply), list of resources created, how to set GitHub Actions SP and reader access, optional CLI examples. |

---

## Generated / runtime files (do not edit by hand)

| File / folder | Purpose |
|----------------|--------|
| **.terraform/** | Created by `terraform init`. Holds provider plugins and module cache. |
| **terraform.tfstate** | Created/updated by `terraform apply`. JSON description of current Azure resources Terraform manages. Used for plan/apply/destroy. Keep it safe; avoid editing. |
| **terraform.tfstate.backup** | Backup of the previous state before the last apply (if applicable). |

---

## How they work together

1. **variables.tf** defines what can be configured.
2. **terraform.tfvars** (and env vars like `TF_VAR_*`) supply the values.
3. **main.tf** uses those variables to create/update Azure resources.
4. **outputs.tf** exposes names and paths after apply.
5. **README.md** and **FOLDER_STRUCTURE.md** explain how to use the folder and each file.

Run from inside `iac/`: `terraform init` → `terraform plan` → `terraform apply`.
