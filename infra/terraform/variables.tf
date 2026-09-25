variable "project_id" {
  description = "GCP project ID to host analytics resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid GCP project ID (6-30 chars, lowercase letters, digits, hyphens)."
  }
}

variable "bigquery_location" {
  description = "BigQuery dataset location."
  type        = string
  default     = "US"

  validation {
    condition     = can(regex("^[A-Za-z0-9-]+$", var.bigquery_location))
    error_message = "bigquery_location must contain only letters, digits, and hyphens."
  }
}

variable "dev_dataset_id" {
  description = "Development dataset ID."
  type        = string
  default     = "taxi_dbt_dev"

  validation {
    condition     = length(var.dev_dataset_id) <= 1024 && can(regex("^[A-Za-z_][A-Za-z0-9_]*$", var.dev_dataset_id))
    error_message = "dev_dataset_id must be a valid BigQuery dataset ID."
  }
}

variable "prod_dataset_id" {
  description = "Production dataset ID."
  type        = string
  default     = "taxi_dbt_prod"

  validation {
    condition     = length(var.prod_dataset_id) <= 1024 && can(regex("^[A-Za-z_][A-Za-z0-9_]*$", var.prod_dataset_id))
    error_message = "prod_dataset_id must be a valid BigQuery dataset ID."
  }
}

variable "ci_service_account_id" {
  description = "Service account ID used by GitHub Actions for dbt jobs."
  type        = string
  default     = "github-dbt-ci"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.ci_service_account_id))
    error_message = "ci_service_account_id must be 6-30 chars (lowercase letters, digits, hyphens)."
  }
}

variable "wif_pool_id" {
  description = "Workload Identity Pool ID."
  type        = string
  default     = "github-pool"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}[a-z0-9]$", var.wif_pool_id))
    error_message = "wif_pool_id must be 4-32 chars (lowercase letters, digits, hyphens)."
  }
}

variable "wif_provider_id" {
  description = "Workload Identity Pool Provider ID."
  type        = string
  default     = "github-provider"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}[a-z0-9]$", var.wif_provider_id))
    error_message = "wif_provider_id must be 4-32 chars (lowercase letters, digits, hyphens)."
  }
}

variable "github_owner" {
  description = "GitHub org/user that owns the repo."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9]([A-Za-z0-9-]{0,37}[A-Za-z0-9])?$", var.github_owner))
    error_message = "github_owner must be a valid GitHub user/org name."
  }
}

variable "github_repo" {
  description = "GitHub repository name."
  type        = string
  default     = "nyc-tlc-trips"

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9._-]{0,99}$", var.github_repo))
    error_message = "github_repo must be a valid GitHub repository name."
  }
}

variable "enable_apis" {
  description = "Required APIs for BigQuery + WIF based CI."
  type        = set(string)
  default = [
    "bigquery.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com"
  ]
}
