# Ship Survey ETL

ETL pipelines for survey data, run on **Azure Synapse Analytics** and orchestrated via **GitHub** and **GitHub Actions**.

## Project structure

```
ship-survey-etl/
├── data/                  # Optional sample CSVs
├── notebooks/             # ETL notebooks (PySpark)
├── synapse_pipeline/      # Synapse workspace artifacts (exported JSON or templates)
├── scripts/               # Deployment scripts
├── requirements.txt       # Python dependencies
└── README.md
```

## Quick start

1. **Clone** (if needed): `git clone https://github.com/zamanrahimi/ship-survey-etl.git`
2. **Environment**: `pip install -r requirements.txt` (for local dev/notebooks).
3. **Notebooks**: Use `notebooks/` for PySpark ETL; run in Synapse or locally with Spark.
4. **Pipelines**: Define or export pipelines into `synapse_pipeline/` and deploy via `scripts/`.

## GitHub & CI/CD

- Repo: [ship-survey-etl](https://github.com/zamanrahimi/ship-survey-etl)
- **Deploy data to ADLS:** workflow `.github/workflows/deploy-data-to-adls.yml` uploads `data/` to the **ship-survey-csv** container. See [.github/workflows/README.md](.github/workflows/README.md) for one-time setup (Azure service principal + `AZURE_CREDENTIALS` secret).
- Other workflows: add under `.github/workflows/` for build, test, and Synapse deployment.

## Synapse

- Pipeline definitions and linked services live in `synapse_pipeline/`.
- Use `scripts/` to deploy workspace artifacts and trigger pipelines.
