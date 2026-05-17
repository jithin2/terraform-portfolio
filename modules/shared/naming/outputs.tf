# TODO(Step 2): Implement outputs.
#
# output "name" {
#   description = "Full resource name: environment-region-application-resource_type (e.g., prod-eus-payments-aks)."
#   value       = local.name
# }
#
# output "prefix" {
#   description = "Name without resource_type suffix (e.g., prod-eus-payments). Use as a base for secondary resources."
#   value       = local.prefix
# }
#
# output "slug" {
#   description = <<-EOT
#     Name with separators stripped (e.g., prodeuspayments aks → prodeuspayments aks).
#     Use for resources that forbid hyphens: Azure storage accounts, GCS bucket names.
#     Has a lifecycle precondition that errors if length > 24 chars.
#   EOT
#   value = local.slug
# }
#
# output "labels" {
#   description = "Standard label/tag map derived from naming inputs. Apply to all resources in the calling module."
#   value       = local.labels
# }
