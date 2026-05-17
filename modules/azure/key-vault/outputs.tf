output "vault_id" {
  description = "Resource ID of the Key Vault. Use as scope when assigning Key Vault Secrets User or Key Vault Secrets Officer roles."
  value       = azurerm_key_vault.this.id
}

output "vault_uri" {
  description = "URI of the Key Vault (e.g., https://NAME.vault.azure.net/). Use in application configuration and CSI driver SecretProviderClass resources."
  value       = azurerm_key_vault.this.vault_uri
}

output "vault_name" {
  description = "Name of the Key Vault."
  value       = azurerm_key_vault.this.name
}

output "private_endpoint_id" {
  description = "Resource ID of the private endpoint. null when enable_private_endpoint = false."
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.kv[0].id : null
}

output "private_endpoint_ip" {
  description = "Private IP address of the vault's private endpoint NIC. null when enable_private_endpoint = false."
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.kv[0].private_service_connection[0].private_ip_address : null
}
