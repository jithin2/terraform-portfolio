output "secret_ids" {
  description = "Map of secret key to full secret resource ID: projects/PROJECT/secrets/SECRET_ID."
  value       = { for k, v in google_secret_manager_secret.this : k => v.id }
}

output "secret_names" {
  description = "Map of secret key to secret_id (short name). Use when referencing the secret in other GCP resources."
  value       = { for k, v in google_secret_manager_secret.this : k => v.secret_id }
}

output "secret_resource_paths" {
  description = "Map of secret key to latest version resource path: projects/PROJECT/secrets/SECRET_ID/versions/latest. Use in application config. For version-pinned access reference a specific version number in application code instead."
  value       = { for k, v in google_secret_manager_secret.this : k => "${v.id}/versions/latest" }
}
