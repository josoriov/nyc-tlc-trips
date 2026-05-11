# Setup Guide

First-time setup for local dbt development, GCP infrastructure, and GitHub Actions CI/CD.

---

## 1. GCP Project & Infrastructure (Terraform)

### Prerequisites
- Python 3.10+
- dbt with the BigQuery adapter
- Terraform >= 1.6
- `gcloud` CLI authenticated to the target account
- Permissions to manage IAM, BigQuery, and Workload Identity in the target project

### Steps

```bash
# Authenticate once
gcloud auth application-default login
```

**Option A — using `terraform.tfvars` (simple, local):**

```bash
cp infra/terraform/terraform.tfvars.example infra/terraform/terraform.tfvars
```

Edit `infra/terraform/terraform.tfvars`:
- Set `project_id` to your GCP project ID
- Set `github_owner` to your GitHub username or org
- Set `github_repo` (default: `nyc-tlc-trips`)
- Keep `create_project = false` if the project already exists
- If creating a new project: set `create_project = true`, `billing_account`, and `org_id` or `folder_id`

```bash
cd infra/terraform
terraform init
terraform plan
terraform apply
```

**Option B — using `.env.tfvars` (recommended, safer):**

```bash
cp infra/terraform/.env.tfvars.example infra/terraform/.env.tfvars
```

Edit `infra/terraform/.env.tfvars` — only `TF_VAR_*` keys are accepted by the wrapper.

```bash
cd infra/terraform
./scripts/tf-safe.sh init
./scripts/tf-safe.sh plan
./scripts/tf-safe.sh apply
```

> **Safety note:** `terraform.tfvars` and `.env.tfvars` are both gitignored.
> The `tf-safe.sh` script rejects any key that is not prefixed with `TF_VAR_`,
> preventing accidental `source`/`eval` of untrusted values.
> `.terraform.lock.hcl` is safe to commit and pins Terraform provider versions.

### Verify

```bash
terraform output project_id
terraform output ci_service_account_email
terraform output workload_identity_provider_name
```

---

## 2. GitHub Repository Secrets

After Terraform apply, retrieve the values you need:

```bash
cd infra/terraform
terraform output github_secrets_to_set
```

Set the following **secrets** in your GitHub repository
(`Settings → Secrets and variables → Actions → New repository secret`):

| Secret name                       | Value source                              |
|-----------------------------------|-------------------------------------------|
| `GCP_PROJECT_ID`                  | `terraform output project_id`             |
| `GCP_WORKLOAD_IDENTITY_PROVIDER`  | `terraform output workload_identity_provider_name` |
| `GCP_SERVICE_ACCOUNT`             | `terraform output ci_service_account_email`|

> **Safety note:** These values are read by GitHub Actions workflows via
> `${{ secrets.* }}` and passed to dbt through environment variables using
> dbt's `{{ env_var() }}` Jinja function — no secrets are written to files
> or exposed in logs.
> These are Workload Identity Federation identifiers, not service account JSON keys.

---

## 3. Local dbt Profile

Create your local `profiles.yml` (already gitignored):

```bash
cp profiles.yml.template ~/.dbt/profiles.yml
```

Edit `~/.dbt/profiles.yml`:
- Replace `your-gcp-project-id` with your actual GCP project ID in **both** targets

If you prefer to keep the profile in the repo during local development, copy
the template to `profiles.yml` in the project root instead and run dbt with
`--profiles-dir .`. The file is gitignored.

---

## 4. First Local Run

```bash
# Install dbt packages
dbt deps

# Verify connectivity
dbt debug --target dev

# Load the taxi zone seed
dbt seed --target dev

# Build everything (staging → intermediate → marts + tests)
dbt build --target dev
```

### Adjust the date window (optional)

The default dev window is `2022-01-01` to `2022-04-01` (3 months).
To change it, either edit `dbt_project.yml` vars or override via CLI:

```bash
dbt build --target dev --vars '{"start_date": "2022-01-01", "end_date": "2022-07-01"}'
```

---

## 5. Generate & View Docs

Use dbt Core for local docs generation if your dbt Fusion version does not
support the docs site commands yet.

```bash
dbt docs generate --target dev
dbt docs serve
```

---

## 6. Push & Verify CI/CD

1. Push the code to a branch and open a PR against `main`.
   - The **CI workflow** (`.github/workflows/ci.yml`) should trigger, authenticate via WIF, and run `dbt compile` + `dbt build` against `taxi_dbt_dev`.

2. Merge the PR to `main`.
   - The **deploy workflow** (`.github/workflows/deploy.yml`) should trigger, build against `taxi_dbt_prod`, generate docs, and cache the manifest for future slim CI.

3. The **nightly workflow** (`.github/workflows/nightly.yml`) runs at 06:00 UTC daily.
   You can also trigger it manually from the Actions tab (`workflow_dispatch`).

> Fusion note: the existing GitHub Actions workflows use dbt Core plus GitHub
> Workload Identity Federation. BigQuery Workload Identity Federation is not a
> currently supported Fusion authentication path, so keep these workflows on
> dbt Core or change auth before migrating CI to Fusion.

---

## 7. Dashboard (optional)

Connect a BI tool (Looker Studio, Metabase, etc.) to BigQuery and point it at:
- `taxi_dbt_prod.fct_daily_citywide_metrics`
- `taxi_dbt_prod.fct_daily_zone_metrics`
- `taxi_dbt_prod.fct_trips`

Update `models/exposures.yml` with the actual dashboard URL and owner email.

---

## Environment Variables Summary

| Context         | Variable / Secret               | How it's used                                      |
|-----------------|---------------------------------|----------------------------------------------------|
| Terraform       | `TF_VAR_*` in `.env.tfvars`     | Parsed by `tf-safe.sh` (no `source`/`eval`)        |
| GitHub Actions  | `GCP_PROJECT_ID` (secret)       | Passed as env var → dbt's `{{ env_var() }}`        |
| GitHub Actions  | `GCP_WORKLOAD_IDENTITY_PROVIDER`| Used by `google-github-actions/auth` for WIF       |
| GitHub Actions  | `GCP_SERVICE_ACCOUNT`           | Service account impersonated via WIF               |
| Local dbt       | `~/.dbt/profiles.yml`           | Contains project ID directly — file is gitignored  |

## Local Files That Must Stay Out Of Git

The repository ignores local secrets and generated artifacts:

- `profiles.yml`
- `.env`, `.env.local`, `.env.*.local`
- `infra/terraform/.env.tfvars`
- `infra/terraform/terraform.tfvars`
- Terraform state, plans, and `.terraform/`
- `target/`, `logs/`, `dbt_packages/`
- `.venv/`

Before committing, check:

```bash
git status --short --ignored
```
