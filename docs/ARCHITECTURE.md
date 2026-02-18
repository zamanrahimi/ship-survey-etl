# Ship Survey ETL – Architecture Overview

High-level view of what exists and what completes the ELT pipeline.

---

## Current state (done)

| Layer | What you have |
|--------|----------------|
| **Infra** | Terraform: ADLS Gen2 storage account + medallion containers (bronze, silver, golden) |
| **Extract / Load** | GitHub Actions: moves CSV from `data/` to **bronze** (ship-bronze-data) on push to main |
| **Transform** | Not yet – data sits in bronze only |

---

## Target ELT flow (overview)

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────────────────────────┐
│  Source         │     │  Land (bronze)    │     │  Process (silver → golden)           │
│  data/*.csv     │ ──► │  ship-bronze-data │ ──► │  ship-silver-data → ship-golden-data │
│  (repo / manual)│     │  raw CSVs         │     │  clean, typed, aggregated            │
└─────────────────┘     └──────────────────┘     └─────────────────────────────────────┘
        │                          │                              │
        │                          │                              │
        ▼                          ▼                              ▼
   GitHub Actions            ADLS Gen2                    Transform engine
   (push → upload)            (you have this)               (to add)
```

---

## What else to complete the ELT

### 1. Transform (bronze → silver → golden)

- **Bronze** (done): raw CSVs as landed.
- **Silver**: clean and standardize
  - Read CSV from bronze, validate schema, fix types (dates, numbers), dedupe, optional partition by date.
  - Write as Parquet or Delta into `ship-silver-data`.
- **Golden**: business-ready
  - Aggregations, KPIs, star/snowflake-style tables for reporting.
  - Write into `ship-golden-data`.

**Options for the T:**

| Option | Pros | Cons |
|--------|------|------|
| **Azure Synapse (Spark)** | Managed Spark, good for ADLS, SQL + Spark | Need Synapse workspace |
| **Azure Data Factory + Mapping Data Flows** | Low-code, same subscription | Less flexible for complex logic |
| **Databricks** | Strong Spark, Delta | Extra service/cost |
| **GitHub Actions + script** | Reuse existing CI, no new service | Limited scale, not ideal for big data |
| **Synapse serverless SQL** | SQL over files in ADLS | Good for querying; transforms often need Spark/ADF |

### 2. Orchestration / scheduling

- Today: load runs when you push to `data/`.
- To complete ELT: something must run the **transform** (and optionally the load) on a **schedule** or when new data lands.
  - **Azure Data Factory** or **Synapse pipelines**: trigger on schedule or on blob arrival; call Spark/ADF flows.
  - **GitHub Actions** (scheduled workflow): can run a script that does bronze→silver→golden (e.g. Python + Spark or Pandas); good for small/medium data.
  - **Azure Functions** (timer): trigger a job that runs the transform.

### 3. Schema and validation

- Define expected schema for ship survey CSV (columns, types).
- Validate on ingest (bronze) or at silver (e.g. Great Expectations, Pandas, or Spark schema).
- Reject or quarantine bad rows; log quality metrics.

### 4. Serving / consumption (optional)

- **Reporting**: Power BI or Synapse SQL over `ship-golden-data` (e.g. external tables / OPENROWSET).
- **APIs**: Azure Functions or API Management on top of golden layer.
- **Downstream apps**: read from golden via Synapse, Databricks, or direct ABFS.

### 5. Observability (optional)

- Pipeline: success/failure alerts (e.g. ADF alerts, GitHub Actions notifications).
- Data quality: row counts, null rates, simple checks in silver/golden.
- Lineage: document or tool (e.g. Purview) for bronze → silver → golden.

---

## Minimal “complete” ELT (next steps)

1. **Transform job**: one or more jobs that read from bronze, write silver (cleaned), then golden (curated). Implement with Synapse Spark, ADF, or a script in GitHub Actions depending on data size and tools.
2. **Orchestration**: run that transform on a schedule or after new data lands (e.g. ADF pipeline or scheduled GitHub Actions).
3. **Schema**: define and enforce schema for ship survey data in silver (and optionally validate at bronze).

After that, add serving and observability as needed.

---

## One-page diagram

```
                    SHIP SURVEY ETL

  [Repo data/]          [ADLS Gen2 – Medallion]
       │
       │  GitHub Actions
       │  (push → upload)
       ▼
  ┌─────────────┐     Transform      ┌─────────────┐     Transform      ┌─────────────┐
  │   BRONZE    │ ─────────────────► │   SILVER    │ ─────────────────► │   GOLDEN   │
  │ raw CSVs    │  (clean, type,     │ Parquet/    │  (aggregate,       │ reporting  │
  │             │   dedupe)          │  Delta      │   business logic)  │  ready     │
  └─────────────┘                    └─────────────┘                    └─────────────┘
       ▲                                    │                                    │
       │                                    │                                    │
  Terraform +                           Orchestration                      Power BI /
  GitHub Actions                        (ADF / Synapse /                   Synapse SQL /
  (you have this)                       scheduled job)                     APIs
```
