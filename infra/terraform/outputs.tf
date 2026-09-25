output "project_id" {
  description = "Target GCP project ID."
  value       = var.project_id
}

output "dev_dataset" {
  description = "Development BigQuery dataset name."
  value       = google_bigquery_dataset.dev.dataset_id
}

output "prod_dataset" {
  description = "Production BigQuery dataset name."
  value       = google_bigquery_dataset.prod.dataset_id
}

output "ci_service_account_email" {
  description = "Service account used by GitHub Actions."
  value       = google_service_account.ci.email
}

output "workload_identity_provider_name" {
  description = "Full WIF provider resource name. Set this as GCP_WORKLOAD_IDENTITY_PROVIDER in GitHub secrets."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "github_secrets_to_set" {
  description = "Secrets required by GitHub Actions."
  value = {
    GCP_PROJECT_ID                 = var.project_id
    GCP_WORKLOAD_IDENTITY_PROVIDER = google_iam_workload_identity_pool_provider.github.name
    GCP_SERVICE_ACCOUNT            = google_service_account.ci.email
  }
}
