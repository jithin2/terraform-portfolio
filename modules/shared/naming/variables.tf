variable "environment" {
  description = "Deployment environment. Propagated as a label/tag on all resources in the calling module."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "region_abbreviation" {
  description = <<-EOT
    Short region code. Caller is responsible for consistency across clouds.
    Recommended convention: Azure = eus (eastus), wus (westus2), neu (northeurope).
                            GCP   = ue1 (us-east1), uw1 (us-west1), euw1 (europe-west1).
    Maximum 6 characters to keep the total name length manageable.
  EOT
  type        = string

  validation {
    condition     = length(var.region_abbreviation) <= 6
    error_message = "region_abbreviation must be 6 characters or fewer to keep names within resource limits."
  }
}

variable "application" {
  description = "Application or workload identifier. Keep short (12 chars or fewer) to avoid hitting Azure storage account and GCS bucket name length limits."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.application))
    error_message = "application must be lowercase alphanumeric and hyphens only."
  }
}

variable "resource_type" {
  description = "Short resource-type suffix appended to the full name (e.g., aks, vnet, kv, gke, vpc, sm, sa)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.resource_type))
    error_message = "resource_type must be lowercase alphanumeric only — no hyphens, as it is a suffix appended after the separator."
  }
}

variable "separator" {
  description = "Character used to join name segments. The default hyphen works for most Azure and GCP resources."
  type        = string
  default     = "-"
}
