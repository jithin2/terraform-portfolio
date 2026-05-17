# TODO(Step 2): Implement variables.
#
# variable "environment" {
#   description = "Deployment environment. Drives name prefix and is propagated as a label/tag."
#   type        = string
#   validation {
#     condition     = contains(["dev", "staging", "prod"], var.environment)
#     error_message = "environment must be one of: dev, staging, prod."
#   }
# }
#
# variable "region_abbreviation" {
#   description = <<-EOT
#     Short region code. Caller is responsible for consistency across clouds.
#     Recommended convention: Azure = eus (eastus), wus (westus2), neu (northeurope).
#                             GCP   = ue1 (us-east1), uw1 (us-west1), euw1 (europe-west1).
#   EOT
#   type = string
#   validation {
#     condition     = length(var.region_abbreviation) <= 6
#     error_message = "region_abbreviation must be 6 characters or fewer to keep names within resource limits."
#   }
# }
#
# variable "application" {
#   description = "Application or workload identifier. Keep short (<=12 chars) to avoid hitting name length limits."
#   type        = string
#   validation {
#     condition     = can(regex("^[a-z0-9-]+$", var.application))
#     error_message = "application must be lowercase alphanumeric and hyphens only."
#   }
# }
#
# variable "resource_type" {
#   description = "Short resource-type suffix appended to the name (e.g., aks, vnet, kv, gke, vpc, sm, sa)."
#   type        = string
#   validation {
#     condition     = can(regex("^[a-z0-9]+$", var.resource_type))
#     error_message = "resource_type must be lowercase alphanumeric only (no hyphens — it is a suffix, not a segment)."
#   }
# }
#
# variable "separator" {
#   description = "Character used to join name segments. Default hyphen works for most Azure and GCP resources."
#   type        = string
#   default     = "-"
# }
