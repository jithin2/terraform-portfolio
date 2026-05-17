output "aks_cluster_name" {
  description = "Name of the AKS cluster."
  value       = module.aks.cluster_name
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL — pass to azurerm_federated_identity_credential when setting up Workload Identity."
  value       = module.aks.oidc_issuer_url
}

output "key_vault_uri" {
  description = "Key Vault URI for application configuration."
  value       = module.key_vault.vault_uri
}

output "vnet_subnet_ids" {
  description = "Map of subnet name to subnet ID."
  value       = module.vnet.subnet_ids
}
