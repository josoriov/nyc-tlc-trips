# NYC TLC Trips Analytics

dbt project that transforms **NYC yellow taxi trip records** from the **BigQuery public dataset** into clean, tested, analytics-ready marts. The first version includes local development setup, Terraform-managed BigQuery/GitHub Actions infrastructure, and CI/CD workflows for pull requests, production deploys, and nightly validation.

## Goals
- Demonstrate **dbt fundamentals**: sources, staging, marts, tests, docs, macros
- Use **warehouse-first modeling** in **BigQuery** with partitioned and clustered marts
- Provide **CI/CD** for analytics via **GitHub Actions**: PR checks, prod deploy, nightly runs
- Produce **dashboard-ready tables** that answer real questions about taxi demand and revenue

## Dataset
- BigQuery public table: `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
- Dimensional enrichment: Taxi Zone Lookup (seeded CSV mapping `LocationID → Borough/Zone`)

## Tech stack
- **dbt** (transformations, tests, docs)
- **BigQuery** (warehouse)
- **Terraform** (GCP datasets, IAM, Workload Identity Federation)
- **GitHub Actions** (CI/CD)
- Optional: **Looker Studio/Metabase** (dashboard)

---

## Architecture

### Datasets / environments
- `taxi_dbt_dev` — development target (used by PR builds / local dev)
- `taxi_dbt_prod` — production target (built on merges to `main`)

### dbt layers
- `sources/` — definitions for BigQuery public tables
- `staging/` — cleaned/typed canonical staging models
- `intermediate/` — feature engineering + reusable business logic
- `marts/` — facts/dimensions/aggregates for analytics and BI

---

## What this project builds

### Core models
- **`stg_taxi__yellow_trips`**  
  Clean and standardize trip records (types, names, filters)

- **`dim_zones`**  
  Taxi zone dimension from seeded lookup table

- **`int_trips__features`**  
  Derived fields like duration, speed, time flags, airport flags

- **`fct_trips`**  
  Trip-level fact table (partitioned by date, clustered for performance)

- **`fct_daily_citywide_metrics`**  
  Daily rides, revenue, tips, durations

- **`fct_daily_zone_metrics`**  
  Daily metrics by pickup zone

### Data quality
- Schema tests: `not_null`, `accepted_values`, `relationships`
- Custom sanity checks: non-negative fares/distances, reasonable durations, etc.

### Current build scope
The default development window is configured in `dbt_project.yml`:

```yaml
vars:
  start_date: "2022-01-01"
  end_date: "2022-04-01"
```

Keep this window small while developing to control BigQuery scan costs. Expand it intentionally for production or larger analyses.

---

## Repo structure

```
.
├── models/
│   ├── sources/          # BigQuery public dataset declarations
│   ├── staging/          # Cleaned/typed canonical models
│   ├── intermediate/     # Feature engineering & business logic
│   ├── marts/            # Facts, dimensions, aggregates
│   └── exposures.yml     # Dashboard dependencies
├── macros/               # safe_divide, safe_int64, is_valid_trip
├── seeds/                # taxi_zone_lookup.csv
├── analysis/
├── scripts/              # Python helpers (download_seed_data.py)
├── infra/terraform/      # GCP infrastructure
├── .github/workflows/    # CI, deploy, nightly workflows
├── dbt_project.yml
├── packages.yml
├── package-lock.yml
├── profiles.yml.template
├── setup.md              # First-time setup and operations guide
├── README.md
└── LICENSE
```

---

## Fusion compatibility

This project parses and compiles successfully on the dbt Fusion engine using
`dbt-fusion 2.0.0-preview.175`:

```bash
dbt deps --use-v2-compatible-package-downloads
dbt parse --show-all-deprecations --target dev
dbt compile --target dev
dbt compile --target dev --static-analysis strict
```

The local `dbt` command in this workspace is Fusion-backed. If you install the
Fusion CLI under a separate command name, use that command for the same checks.

Current Fusion notes:
- `dbt debug` requires a real `nyc_tlc_trips` profile and GCP project ID. The
  checked-in `profiles.yml.template` intentionally uses placeholders.
- Local `dbt docs generate` / `dbt docs serve` may require dbt Core depending
  on your Fusion version.
- The GitHub Actions workflows use Workload Identity Federation with dbt Core.
  BigQuery Workload Identity Federation is not currently a Fusion-supported
  authentication path, so a future Fusion CI migration should switch auth or
  wait for Fusion support.

---

## Quickstart

### 1) Prerequisites
- Python 3.10+
- dbt Core with the BigQuery adapter, or the dbt Fusion CLI for Fusion checks
- Access to a GCP project + BigQuery

### 2) BigQuery setup
Create two datasets in your GCP project, or use the Terraform setup in `setup.md`:
- `taxi_dbt_dev`
- `taxi_dbt_prod`

### 3) Authentication
For local development, authenticate with Application Default Credentials:

```bash
gcloud auth application-default login
```

For CI/CD, this project uses GitHub OIDC with Google Workload Identity Federation.

### 4) Configure dbt profile
Create a local `profiles.yml` (do not commit it). Example targets:
- `dev` → dataset `taxi_dbt_dev`
- `prod` → dataset `taxi_dbt_prod`

Quick start from the repo template:
```bash
cp profiles.yml.template ~/.dbt/profiles.yml
```

### 5) Run locally
```bash
dbt deps
dbt debug --target dev
dbt build --target dev
```

Generate docs:
```bash
dbt docs generate --target dev
dbt docs serve
```

> Fusion note: use dbt Core for local docs generation for now. Fusion can parse
> and compile this project, but local docs site generation is still a current
> Fusion limitation.

See `setup.md` for the complete Terraform, GitHub Actions, and first-run guide.

---

## CI/CD with GitHub Actions

### Pull Request workflow (CI)
Runs on PR:
- `dbt deps`
- `dbt compile`
- `dbt build` against the **dev** dataset, using slim CI when a production manifest is cached

### Main branch workflow (CD)
Runs on push to `main`:
- `dbt build` against the **prod** dataset
- `dbt docs generate`
- Uploads docs artifacts and caches the production manifest

### Nightly workflow
Runs on a schedule:
- `dbt build` against the **prod** dataset to detect data quality drift

---

## Cost control
BigQuery can be expensive if you scan too much data.
This project defaults to a **date window** using dbt vars for development. Expand the window once everything is stable.

---
## Results

### Questions this project supports
- **Where is taxi demand highest?** — `fct_daily_zone_metrics` shows trip volume and revenue by zone per day, revealing hot-spots like Midtown, JFK, and the Financial District.
- **When do passengers ride?** — Time features (`pickup_hour`, `is_weekend`, `is_night`) in `fct_trips` support peak-hour and day-of-week analysis.
- **How much revenue do airports generate?** — The `is_airport_pickup` flag lets you isolate Newark, JFK, and LaGuardia trips for revenue comparison.
- **What are citywide trends?** — `fct_daily_citywide_metrics` provides a single-row-per-day summary of rides, revenue, tips, and segment breakdowns.
- **How fast are taxis?** — `speed_mph` in `int_trips__features` enables speed distribution analyses by zone or time of day.

### dbt lineage
Generate the lineage graph locally with:

```bash
dbt docs generate --target dev
dbt docs serve
```

### Dashboard
The exposure in `models/exposures.yml` documents the intended dashboard dependencies. Add the dashboard URL there after connecting a BI tool to the production marts.

---
## Security
Do not commit local credentials or generated artifacts. The `.gitignore` excludes dbt outputs, logs, profiles, local env files, Terraform state/tfvars/plans, provider caches, virtual environments, and editor files.

Safe templates are committed for local setup:
- `profiles.yml.template`
- `infra/terraform/.env.tfvars.example`
- `infra/terraform/terraform.tfvars.example`

## Useful Commands

```bash
# Refresh package dependencies
dbt deps

# Compile without building tables
dbt compile --target dev

# Full local dev build
dbt build --target dev

# Override the date window
dbt build --target dev --vars '{"start_date": "2022-01-01", "end_date": "2022-07-01"}'

# Refresh the zone lookup seed file
python scripts/download_seed_data.py
```

---

## License
See `LICENSE`.
