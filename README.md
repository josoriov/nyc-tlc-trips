# NYC TLC Trips Analytics

A small dbt/BigQuery project that turns NYC yellow-taxi public data into
dashboard-ready logical views without storing source or transformed data.

## Architecture

![NYC TLC Trips architecture: Terraform provisions identity and datasets; GitHub Actions authenticates through Workload Identity Federation and runs dbt; public trips and taxi zones feed five BigQuery logical views.](docs/architecture/architecture.svg)

[Explore the interactive architecture](docs/architecture/architecture.html) by downloading
the HTML file and opening it in a browser. It includes light/dark themes,
source-code links, and image exports, and works offline.

Solid arrows show SQL dependencies, not copied data. Dashed arrows show
provisioning and builds; the security arrow shows keyless authentication.
Citywide metrics roll up the zone aggregates. The dashboard exposure is planned;
there is no live dashboard yet.

## What it builds

| Model | Type | Purpose |
|---|---|---|
| `stg_taxi__yellow_trips` | view | Clean and type source trips |
| `dim_zones` | view | TLC zone lookup |
| `fct_trips` | view | Add duration, speed, time, airport, and zone fields |
| `fct_daily_citywide_metrics` | view | Daily citywide demand and revenue |
| `fct_daily_zone_metrics` | view | Daily demand and revenue by pickup zone |

The default window is January–March 2022. Change `start_date` and `end_date`
in `dbt_project.yml` when a larger sample is worth the additional query cost.

## Why this shape

- The public BigQuery table remains the source of truth.
- Every model is a logical view, so the project stores no model data.
- Taxi zones come from the public dataset instead of a local seed table.
- Pull requests parse the project without authenticating to or querying GCP.
- Production builds run when `main` changes and monthly to renew sandbox views.
- Tests cover representative null, accepted-value, uniqueness, and relationship
  checks without rescanning the source for every column.

## Local use

Requirements: Python 3.10+, `dbt-bigquery`, a GCP project with BigQuery, and
Application Default Credentials.

```bash
pip install dbt-bigquery
gcloud auth application-default login
cp profiles.yml.template profiles.yml
GCP_PROJECT_ID=your-gcp-project-id dbt build --profiles-dir . --target dev
```

Generate dbt documentation when needed:

```bash
GCP_PROJECT_ID=your-gcp-project-id dbt docs generate --profiles-dir . --target dev
dbt docs serve
```

## Infrastructure

Terraform creates two datasets, a GitHub Actions service account, and Workload
Identity Federation in an existing GCP project.

```bash
cp infra/terraform/terraform.tfvars.example infra/terraform/terraform.tfvars
terraform -chdir=infra/terraform init
terraform -chdir=infra/terraform plan
terraform -chdir=infra/terraform apply
terraform -chdir=infra/terraform output github_secrets_to_set
```

For a replacement project, set its ID in the ignored local file:

```hcl
# infra/terraform/terraform.tfvars
project_id = "your-new-gcp-project-id"
```

Use a new Terraform workspace so the previous project's state is not reused:

```bash
terraform -chdir=infra/terraform workspace new your-new-gcp-project-id
terraform -chdir=infra/terraform plan
terraform -chdir=infra/terraform apply
```

Add those three output values as repository Actions secrets:

- `GCP_PROJECT_ID`
- `GCP_WORKLOAD_IDENTITY_PROVIDER`
- `GCP_SERVICE_ACCOUNT`

Set `GCP_PROJECT_ID` in your shell for local dbt commands. In GitHub, put it
under **Settings → Secrets and variables → Actions → Repository secrets**.
Because Workload Identity resources belong to the new project, replace all
three GitHub secrets with the new Terraform outputs.

The datasets contain only logical views. Production has `prevent_destroy`;
inspect every Terraform plan before applying it.

## Automation

- `.github/workflows/ci.yml`: offline `dbt parse` for pull requests.
- `.github/workflows/deploy.yml`: authenticated `dbt build` after a merge,
  manual dispatch, and on the first day of each month. The monthly refresh
  keeps sandbox views alive without daily jobs or persistent model storage.
- `tests/query_quota.sql`: fails the authenticated build when this month's
  billed queries reach 80% of BigQuery Sandbox's 1 TiB allowance, using the
  existing GitHub Actions failure notification as the alert.

The project does not need a storage monitor: its dbt objects are logical views,
so they consume no BigQuery storage quota.

## Data

- Trips: `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
- Zones: `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`

The marts support citywide and zone demand, revenue, airport trips, passenger
counts, trip duration, distance, and time-of-day analysis.

## License

See `LICENSE`.
