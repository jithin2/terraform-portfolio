# TODO(Step 3): Implement variables.
#
# variable "project_id" { type = string }
#
# variable "secrets" {
#   description = "Map of secrets to create. Key becomes the secret_id."
#   type = map(object({
#     replication_type = optional(string, "automatic")  # "automatic" or "user_managed"
#     replica_locations = optional(list(string), [])    # required when replication_type = "user_managed"
#     initial_value    = optional(string, null)          # WARNING: stored in Terraform state
#     labels           = optional(map(string), {})
#   }))
# }
#
# variable "iam_bindings" {
#   description = <<-EOT
#     List of IAM bindings to create on individual secrets.
#     Uses google_secret_manager_secret_iam_member (additive) — does not overwrite
#     bindings managed outside this module.
#
#     Example:
#       [{
#         secret_key = "db-password"
#         role       = "roles/secretmanager.secretAccessor"
#         member     = "serviceAccount:my-sa@project.iam.gserviceaccount.com"
#       }]
#   EOT
#   type = list(object({
#     secret_key = string
#     role       = string
#     member     = string
#   }))
#   default = []
# }
#
# variable "labels" {
#   type        = map(string)
#   default     = {}
#   description = "Labels applied to all secrets in this module. Merged with per-secret labels."
# }
