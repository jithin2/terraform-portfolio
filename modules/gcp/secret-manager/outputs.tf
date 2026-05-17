# TODO(Step 3): Implement outputs.
#
# output "secret_ids" {
#   description = "Map of secret key → secret resource ID (projects/PROJECT/secrets/SECRET_ID)."
# }
#
# output "secret_names" {
#   description = "Map of secret key → secret_id string (the short name, not the full resource path)."
# }
#
# output "secret_resource_paths" {
#   description = <<-EOT
#     Map of secret key → latest version resource path
#     (projects/PROJECT/secrets/SECRET_ID/versions/latest).
#     Use this in application config to reference the secret.
#     NOTE: 'latest' always resolves to the newest enabled version at runtime —
#     if you need version pinning, reference a specific version number here or in app code.
#   EOT
# }
