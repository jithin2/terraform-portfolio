variable "resource_group_name" {
  description = "Name of the Azure resource group where the Key Vault is deployed."
  type        = string
}

variable "location" {
  description = "Azure region for the Key Vault (e.g., eastus, westeurope)."
  type        = string
}

variable "name" {
  description = "Key Vault name. Must be globally unique, 3–24 characters, alphanumeric and hyphens only. Use module.naming.slug to derive a safe name."
  type        = string

  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 24 && can(regex("^[a-zA-Z0-9-]+$", var.name))
    error_message = "Key Vault name must be 3–24 characters, alphanumeric and hyphens only."
  }
}

variable "sku_name" {
  description = "Key Vault SKU. Use premium if HSM-backed keys are required."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be standard or premium."
  }
}

variable "soft_delete_retention_days" {
  description = "Number of days soft-deleted vaults and objects are retained. Cannot be reduced after being set."
  type        = number
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90."
  }
}

variable "purge_protection_enabled" {
  description = "Prevent force-purge of soft-deleted vaults. Once enabled this cannot be disabled and the vault name cannot be reused until the retention period expires. Set false only for dev environments."
  type        = bool
  default     = true
}

variable "enable_rbac_authorization" {
  description = "Use Azure RBAC for data-plane access instead of vault access policies. Recommended for new deployments — access policies are limited to 1024 entries and cannot use PIM."
  type        = bool
  default     = true
}

variable "network_acls" {
  description = "Network ACLs for the vault. Default-deny with AzureServices bypass is the secure baseline. In private-endpoint mode leave ip_rules and virtual_network_subnet_ids empty."
  type = object({
    default_action             = optional(string, "Deny")
    bypass                     = optional(string, "AzureServices")
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default = {}

  validation {
    condition     = contains(["Allow", "Deny"], var.network_acls.default_action)
    error_message = "network_acls.default_action must be Allow or Deny."
  }
}

variable "enable_private_endpoint" {
  description = "Create a private endpoint for the vault. When true, set network_acls.default_action = Deny and leave virtual_network_subnet_ids empty — the two access patterns are mutually exclusive."
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the private endpoint NIC. The subnet must have private_endpoint_network_policies = Disabled. Required when enable_private_endpoint = true."
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Resource ID of the private DNS zone for privatelink.vaultcore.azure.net. When provided the private endpoint is registered in this zone automatically."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
