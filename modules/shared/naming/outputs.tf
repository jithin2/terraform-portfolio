output "name" {
  description = "Full resource name in the pattern environment-region-application-resource_type (e.g., prod-eus-payments-aks)."
  value       = local.name
}

output "prefix" {
  description = "Name without the resource_type suffix (e.g., prod-eus-payments). Use as a base when naming secondary or related resources."
  value       = local.prefix
}

output "slug" {
  description = "Name with separators stripped (e.g., prodeuspayments aks). Use for resources that forbid hyphens: Azure storage accounts, GCS bucket names."
  value       = local.slug
}

output "labels" {
  description = "Standard label/tag map derived from naming inputs. Merge with caller-specific tags before applying: merge(module.naming.labels, var.additional_tags)."
  value       = local.labels
}
