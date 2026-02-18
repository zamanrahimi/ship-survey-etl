# Bronze → silver pipeline (serverless SQL) – maintained in GitHub

**Everything is controlled from GitHub:** the SQL script lives in the repo, and the deploy workflow runs it **after** data is moved to bronze.

---

## Flow: data in bronze → then run Synapse SQL job

1. **GitHub Actions** uploads CSV from `data/` to **bronze** (ship-bronze-data).
2. **Same workflow** runs the Synapse serverless SQL job (script in `synapse/sql/bronze_to_silver_top5.sql`).
3. The SQL runs on the Synapse workspace (created by IaC) and queries bronze (e.g. SELECT TOP 5). You can extend it to write to silver (CETAS or Copy in a Synapse pipeline).

So: **pipeline logic is in GitHub** (`synapse/sql/*.sql`); **when** it runs is “right after data lands in bronze.”

---

## What you need to run the Synapse SQL step (no Synapse secrets)

The workflow uses the **same service principal** as for ADLS (Azure AD auth). Terraform grants that SP **Synapse SQL Administrator** on the workspace, so you do **not** need any Synapse-related secrets in GitHub.

| Where | What to set |
|--------|-------------|
| **GitHub → Settings → Variables (Actions)** | `SYNAPSE_WORKSPACE_NAME` = your Synapse workspace name (e.g. `ship-synapse-survey-etl`). |

That’s it. No `SYNAPSE_SQL_ADMIN_PASSWORD` or `SYNAPSE_SQL_ADMIN_USER`. If `SYNAPSE_WORKSPACE_NAME` is set, the workflow runs the SQL after upload using the existing Azure login (SP).

**When to set it:** After you’ve run Terraform and created the Synapse workspace. Then in GitHub → Settings → Variables (Actions) add `SYNAPSE_WORKSPACE_NAME` = your workspace name (e.g. `ship-synapse-survey-etl`, or use `terraform output synapse_workspace_name`).

---

## Where the pipeline is defined

| What | Where (in GitHub) |
|------|--------------------|
| SQL script (what runs) | `synapse/sql/bronze_to_silver_top5.sql` |
| When it runs | `.github/workflows/deploy-data-to-adls.yml` – step “Run Synapse serverless SQL (bronze → silver)” runs after “List uploaded blobs”. |

Edit the SQL file in the repo to change the transform; the workflow runs it automatically after each successful upload to bronze.

---

## Alternative: run only in Synapse Studio (no GitHub step)

You can still run the same logic only inside Synapse (e.g. on a schedule or manually). Below are the original options.

---

## Option A: In Synapse (schedule or manual)

**Create the pipeline inside Azure Synapse.**

- In **Synapse Studio** (portal → your Synapse workspace → Open Synapse Studio):
  1. Go to **Develop** → **SQL scripts** (or **Integrate** → **Pipelines**).
  2. Create a **SQL script** that runs the serverless SQL (e.g. the example below).
  3. To run it on a schedule: **Integrate** → **Pipelines** → New pipeline → add a **Script** activity that runs this SQL (or use a **Stored procedure** / **Notebook** if you prefer).

- **Pros:** Native to Synapse, scheduling and monitoring in one place, no GitHub needed for the transform.
- **Cons:** Pipeline definition lives in Synapse (or in Synapse Git if you connect a repo), not in this GitHub repo.

---

## Option B: In GitHub Actions

**Run the serverless SQL from a workflow step.**

- Add a step that runs the SQL (e.g. via `sqlcmd`, Azure CLI `az synapse sql-script`, or Synapse REST API).
- Example: after “Upload data to ADLS”, trigger a job that executes the SQL script (e.g. from a file in the repo).

- **Pros:** Everything as code in GitHub; one workflow for load + transform.
- **Cons:** Need to store Synapse credentials or use OIDC; more wiring than Option A.

---

## Recommendation

Use **Option A (Synapse)** for the pipeline that processes bronze → silver: create a **Synapse pipeline** (or scheduled SQL script) in Synapse Studio that runs the serverless SQL. Use GitHub Actions only for **loading** CSVs into bronze (as you do now).

---

# Example: SELECT TOP 5 from bronze and write to silver

Below is **serverless SQL** that:

1. Reads `ship_survey.csv` from the **bronze** container.
2. Selects the first 5 rows.
3. Writes the result to the **silver** container (as Parquet).

Replace `YOUR_STORAGE_ACCOUNT` with your ADLS account name (e.g. `shipsurveyetl`). In Synapse, use the workspace’s managed identity to access ADLS (already granted by Terraform).

```sql
-- Run this in Synapse Studio: Develop → SQL script → connect to "Built-in" (serverless SQL).

-- 1) Read ship_survey.csv from bronze (OPENROWSET)
-- Replace YOUR_STORAGE_ACCOUNT with your storage account name (e.g. shipsurveyetl).
DECLARE @storage_account VARCHAR(24) = 'YOUR_STORAGE_ACCOUNT';

SELECT TOP 5
    *
FROM OPENROWSET(
    BULK 'https://' + @storage_account + '.dfs.core.windows.net/ship-bronze-data/ship_survey.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    HEADER_ROW = TRUE
) AS bronze;

-- 2) Create external data source (one-time) so we can write to silver
-- Replace YOUR_STORAGE_ACCOUNT.
CREATE EXTERNAL DATA SOURCE BronzeSilverADLS
WITH (
    LOCATION = 'abfss://ship-bronze-data@YOUR_STORAGE_ACCOUNT.dfs.core.windows.net/',
    CREDENTIAL = [Workspace Identity]  -- or create a credential if needed
);
-- For writing to silver, use a separate data source pointing to ship-silver-data, or use CETAS with full path.

-- 3) CETAS: SELECT TOP 5 from bronze, write result to silver as Parquet
-- (Serverless SQL CETAS writes to the workspace default storage by default; to write to silver you can use an external data source for silver or export.)
CREATE EXTERNAL DATA SOURCE SilverADLS
WITH (
    LOCATION = 'abfss://ship-silver-data@YOUR_STORAGE_ACCOUNT.dfs.core.windows.net/',
    CREDENTIAL = [Workspace Identity]
);

-- Export top 5 rows to silver (example: as CSV in silver; for Parquet you'd use CETAS with external table).
-- Simplified: use a single OPENROWSET and export via CETAS to a location in the workspace, then copy to silver;
-- or use Synapse pipeline Copy activity. Below is a minimal “query only” that you can wrap in a pipeline.
SELECT TOP 5
    survey_id,
    response_date,
    vessel_name,
    vessel_type,
    flag_country,
    crew_size,
    safety_rating,
    satisfaction_rating,
    maintenance_rating,
    port_of_survey
FROM OPENROWSET(
    BULK 'https://YOUR_STORAGE_ACCOUNT.dfs.core.windows.net/ship-bronze-data/ship_survey.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    HEADER_ROW = TRUE
) AS bronze;
-- To actually write to silver from serverless SQL: use CETAS with an external data source for silver (see Synapse docs for CETAS + external location).
```

**Minimal “run in Synapse” version (query only; write to silver via pipeline or manual export):**

```sql
-- Run in Synapse Studio → SQL script (serverless). Replace YOUR_STORAGE_ACCOUNT.
SELECT TOP 5 *
FROM OPENROWSET(
    BULK 'https://YOUR_STORAGE_ACCOUNT.dfs.core.windows.net/ship-bronze-data/ship_survey.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    HEADER_ROW = TRUE
) AS bronze;
```

To **write** those 5 rows into silver, you can:

- Use **Synapse pipeline**: Lookup/Get Metadata → **Script** activity with the SELECT above → **Copy data** to silver (e.g. as Parquet/CSV), or
- Use **CETAS** in serverless SQL with an external data source pointing at `ship-silver-data` (see Azure docs: “CETAS with external data source”).

---

## Summary

| Question | Answer |
|----------|--------|
| Where is the pipeline maintained? | **In GitHub**: `synapse/sql/bronze_to_silver_top5.sql` and `.github/workflows/deploy-data-to-adls.yml`. |
| When does the SQL job run? | **After** data is moved to bronze, in the same deploy workflow (if `SYNAPSE_WORKSPACE_NAME` is set). Uses service principal (Azure AD); no Synapse secrets in GitHub. |
| Example operation | SELECT TOP 5 from `ship_survey.csv` in bronze (OPENROWSET). Extend the SQL or add a Synapse pipeline to write results to silver (CETAS or Copy). |
