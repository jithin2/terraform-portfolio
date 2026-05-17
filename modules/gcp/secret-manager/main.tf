# TODO(Step 3): Implement Secret Manager resources.
#
# Resources:
#
#   google_secret_manager_secret (for_each over var.secrets)
#     · project = var.project_id
#     · secret_id = key from the map (e.g., "db-password", "api-key")
#     · replication block — two patterns:
#         Automatic replication (recommended for most cases):
#           replication { auto {} }
#         User-managed replication (for compliance/data residency):
#           replication { user_managed { replicas { location = "..." } } }
#       The choice between auto and user-managed is driven by compliance requirements,
#       not performance. Auto is simpler; user-managed gives explicit control over regions.
#     · labels from merge(var.labels, secret.labels)
#
#   google_secret_manager_secret_version (for secrets with initial_value set)
#     · secret = google_secret_manager_secret.secrets[key].id
#     · secret_data = var.secrets[key].initial_value (marked sensitive)
#     · NOTE: secret_data is stored in Terraform state. For production, prefer creating
#       secret versions outside Terraform (via CI/CD or a secrets rotation process) and
#       only creating the secret resource (not the version) in Terraform.
#
#   google_secret_manager_secret_iam_member (for_each over flattened var.iam_bindings)
#     · Use for_each with a map keyed by "${secret_key}-${role}-${member_hash}" to
#       ensure stable resource addresses when bindings are added or removed.
#     · secret = google_secret_manager_secret.secrets[binding.secret_key].id
#     · role   = binding.role   (e.g., "roles/secretmanager.secretAccessor")
#     · member = binding.member (e.g., "serviceAccount:SA_EMAIL")
#
# Key design decisions:
#   - Separate google_secret_manager_secret_version from the secret resource.
#     Terraform state contains the secret value in plaintext. Acceptable for bootstrap
#     values; not acceptable for frequently-rotated secrets.
#   - iam_member (additive) not iam_binding (authoritative) to avoid Terraform clobbering
#     bindings managed outside this module (e.g., bindings added by GKE Workload Identity setup).
#   - Flattening iam_bindings into a map for for_each avoids count-based state instability
#     when a binding in the middle of a list is removed.
