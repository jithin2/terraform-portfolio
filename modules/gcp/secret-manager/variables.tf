variable "project_id" {
  description = "GCP project ID where secrets are created."
  type        = string
}

variable "secrets" {
  description = "Map of secrets to create. Key becomes the secret_id."
  type = map(object({
    replication_type  = optional(string, "automatic")
    replica_locations = optional(list(string), [])
    initial_value     = optional(string, null)
    labels            = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for k, v in var.secrets :
      contains(["automatic", "user_managed"], v.replication_type)
    ])
    error_message = "replication_type must be automatic or user_managed for every secret."
  }

  validation {
    condition = alltrue([
      for k, v in var.secrets :
      v.replication_type == "automatic" || length(v.replica_locations) > 0
    ])
    error_message = "replica_locations must be non-empty when replication_type is user_managed."
  }
}

variable "iam_bindings" {
  description = "Additive IAM bindings on individual secrets. Uses google_secret_manager_secret_iam_member — does not overwrite bindings created outside this module."
  type = list(object({
    secret_key = string
    role       = string
    member     = string
  }))
  default = []
}

variable "labels" {
  description = "Labels applied to all secrets. Merged with per-secret labels."
  type        = map(string)
  default     = {}
}
