provider "google" {}

provider "google-beta" {}

locals {
  github_repository = "${var.github_owner}/${var.github_repo}"
}

resource "google_project_service" "required" {
  for_each = var.enable_apis
  project  = var.project_id
  service  = each.value

  disable_on_destroy = false
}

resource "google_bigquery_dataset" "dev" {
  project                     = var.project_id
  dataset_id                  = var.dev_dataset_id
  location                    = var.bigquery_location
  default_table_expiration_ms = 7 * 24 * 60 * 60 * 1000

  delete_contents_on_destroy = false

  depends_on = [google_project_service.required]
}

resource "google_bigquery_dataset" "prod" {
  project                    = var.project_id
  dataset_id                 = var.prod_dataset_id
  location                   = var.bigquery_location
  delete_contents_on_destroy = false

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.required]
}

resource "google_service_account" "ci" {
  account_id   = var.ci_service_account_id
  display_name = "GitHub dbt CI"
  project      = var.project_id

  depends_on = [google_project_service.required]
}

resource "google_project_iam_member" "ci_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.ci.email}"
}

resource "google_project_iam_member" "ci_resource_viewer" {
  project = var.project_id
  role    = "roles/bigquery.resourceViewer"
  member  = "serviceAccount:${google_service_account.ci.email}"
}

resource "google_bigquery_dataset_iam_member" "dev_editor" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.dev.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.ci.email}"
}

resource "google_bigquery_dataset_iam_member" "prod_editor" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.prod.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.ci.email}"
}

resource "google_iam_workload_identity_pool" "github" {
  provider                  = google-beta
  project                   = var.project_id
  workload_identity_pool_id = var.wif_pool_id
  display_name              = "GitHub Actions Pool"
  description               = "OIDC identities for GitHub Actions."

  depends_on = [google_project_service.required]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  provider                           = google-beta
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = var.wif_provider_id
  display_name                       = "GitHub Provider"
  description                        = "GitHub OIDC provider for CI."

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == '${local.github_repository}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github_wif_user" {
  service_account_id = google_service_account.ci.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${local.github_repository}"
}
