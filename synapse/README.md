# Synapse artifacts (maintained in GitHub)

Pipeline logic for bronze → silver runs from **SQL scripts in this folder**. The deploy workflow runs them **after** data is uploaded to bronze.

## Layout

- **`sql/`** – Serverless SQL scripts. The workflow replaces `YOUR_STORAGE_ACCOUNT` with the actual storage account name at run time.
  - `bronze_to_silver_top5.sql` – SELECT TOP 5 from `ship_survey.csv` in bronze (example). Edit this or add new scripts to change the transform.

## How it runs

1. Push to `data/**` or `synapse/**` (or run the workflow manually) → GitHub Actions uploads to bronze.
2. Same workflow runs the Synapse serverless SQL step if **Variables (Actions)** has `SYNAPSE_WORKSPACE_NAME` set.
3. The step uses `sqlcmd` with **Azure AD** (same service principal as for ADLS); no Synapse password in GitHub.

See **`docs/SYNAPSE_PIPELINE.md`** for the full flow.
